/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/
#include <fileformatutils/common.h>
#include <fileformatutils/layerWriteShared.h>

#include <algorithm>
#include <vector>

using namespace PXR_NS;

namespace adobe::usd {

std::string
getSTPrimvarAttrName(int uvIndex)
{
    static std::string stPrimvarName = "stPrimvarName";
    if (uvIndex < 0) {
        TF_WARN("Invalid uvIndex for stPrimvarName %d", uvIndex);
        return stPrimvarName;
    }
    if (uvIndex == 0)
        return stPrimvarName;
    return stPrimvarName + std::to_string(uvIndex);
}

int
parseIntEnding(const std::string& str)
{
    if (str.empty())
        return -1;
    try {
        std::size_t pos{};
        const int i{ std::stoi(str, &pos) };
        if (pos == str.size() && i >= 0) {
            return i;
        }
    } catch (const std::out_of_range&) {
        return -1;
    }
    return -1;
}

// If the token string starts with "st", check if the characters following it can be converted to a
// non-zero int. This is essentially looking for tokens: st, st0, st1, st2, st3, ...
// (note that st and st0 are considered equivalent)
// The number value is returned or -1 if there isn't a pattern match.
int
getSTPrimvarTokenIndex(TfToken token)
{
    std::string const& str = token.GetString();
    if (str.compare(0, 2, "st") == 0) {
        if (str.size() == 2)
            return 0;
        return parseIntEnding(str.substr(2));
    }
    return -1;
}

// return a token with "st" for uvIndex==0, "st1" for uvIndex==1, "st2" for uvIndex==2, ...
TfToken
getSTPrimvarAttrToken(int uvIndex)
{
    if (uvIndex < 0) {
        TF_WARN("Invalid uvIndex [%d] for st primvar: ", uvIndex);
        return TfToken();
    }

    if (uvIndex <= 0)
        return AdobeTokens->st;
    return TfToken(AdobeTokens->st.GetString() + std::to_string(uvIndex));
}

// return a token with "texCoordReader" for uvIndex==0, "texCoordReader1" for uvIndex==1,
// "texCoordReader2" for uvIndex==2, ...
TfToken
getSTTexCoordReaderToken(int uvIndex)
{
    if (uvIndex < 0) {
        TF_WARN("Invalid uvIndex [%d] for texCoordReader", uvIndex);
        return TfToken();
    }
    if (uvIndex == 0)
        return AdobeTokens->texCoordReader;
    return TfToken(AdobeTokens->texCoordReader.GetString() + std::to_string(uvIndex));
}

VtValue
getTextureZeroVtValue(const TfToken& channel)
{
    if (channel == AdobeTokens->r || channel == AdobeTokens->g || channel == AdobeTokens->b ||
        channel == AdobeTokens->a) {
        return VtValue(0.0f);
    } else if (channel == AdobeTokens->rgb) {
        return VtValue(GfVec3f(0.0f));
    } else if (channel == AdobeTokens->rgba) {
        return VtValue(GfVec4f(0.0f));
    } else {
        TF_WARN("getTextureZeroVtValue for unsupported channel %s", channel.GetText());
        return VtValue();
    }
}

std::string
createTexturePath(const std::string& srcAssetFilename, const std::string& imageUri)
{
    return srcAssetFilename.empty() ? imageUri : srcAssetFilename + "[" + imageUri + "]";
}

OpenPbrMaterial
mapMaterialStructToOpenPbrMaterialStruct(const Material& material)
{
    const bool scatter =
      !material.scatteringColor.isEmpty() || !material.scatteringDistance.isEmpty();
    const bool fuzz = !material.sheenColor.isEmpty();
    const bool emission = !material.emissiveColor.isEmpty();

    OpenPbrMaterial result;
    result.name = material.name;
    result.displayName = material.displayName;

    // OpenPBR spec:
    /// This is based on OpenPBR 1.0
    /// https://github.com/AcademySoftwareFoundation/OpenPBR/blob/44fe76650880914980402221672446ad44df15bd/reference/open_pbr_surface.mtlx
    ///
    /// The latest version can be found here (currently at 1.1)
    /// https://github.com/AcademySoftwareFoundation/OpenPBR/blob/main/reference/open_pbr_surface.mtlx

    // Julien Guertault and Peter Kutz have written a guide to convert from ASM to OpenPBR.
    // Note, that the code below does not implement any value remapping as described in this
    // document. We only use the rough input-to-input mapping that is derived from it.

    // base
    // base_weight (no source info)
    result.base_color = material.diffuseColor;
    // base_diffuse_roughness (no source info) Note, this is a diffuse roughness
    result.base_metalness = material.metallic;

    // specular
    result.specular_weight = material.specularLevel;
    result.specular_color = material.specularColor;
    result.specular_roughness = material.roughness;
    result.specular_ior = material.ior;
    result.specular_roughness_anisotropy = material.anisotropyLevel;

    // transmission
    // TODO consider scatter
    result.transmission_weight = material.transmission;
    result.transmission_color = material.absorptionColor;
    result.transmission_depth = material.absorptionDistance;
    // transmission_scatter (no source info)
    // transmission_scatter_anisotropy (no source info)
    // transmission_dispersion_scale (no source info)
    // transmission_dispersion_abbe_number (no source info)

    // subsurface
    result.subsurface_weight = Input{ scatter ? VtValue(1.0f) : VtValue() };
    result.subsurface_color = material.scatteringColor;
    result.subsurface_radius = material.scatteringDistance;
    result.subsurface_radius_scale = material.scatteringDistanceScale;

    // fuzz
    result.fuzz_weight = Input{ fuzz ? VtValue(1.0f) : VtValue() };
    result.fuzz_color = material.sheenColor;
    result.fuzz_roughness = material.sheenRoughness;

    // coat
    result.coat_weight = material.clearcoat;
    result.coat_color = material.clearcoatColor;
    result.coat_roughness = material.clearcoatRoughness;
    // coat_roughness_anisotropy (no source info)
    result.coat_ior = material.clearcoatIor;
    // coat_darkening (no source info)

    // thin_film
    // thin_film_weight (no source info)
    // thin_film_thickness (no source info)
    // thin_film_ior (no source info)

    // emission
    result.emission_luminance = Input{ emission ? VtValue(1.0f) : VtValue() };
    result.emission_color = material.emissiveColor;

    // geometry
    result.geometry_opacity = material.opacity;
    // geometry_thin_walled (no source info)
    result.geometry_normal = material.normal;
    result.geometry_coat_normal = material.clearcoatNormal;
    // geometry_tangent (no source info)
    // geometry_coat_tangent (no source info)

    // Non-OpenPBR inputs
    result.displacement = material.displacement;
    result.occlusion = material.occlusion;
    result.anisotropyAngle = material.anisotropyAngle;
    result.coatSpecularLevel = material.clearcoatSpecular;
    result.volumeThickness = material.volumeThickness;
    if (!material.normalScale.isEmpty() && material.normalScale.value.IsHolding<float>()) {
        result.normalScale = material.normalScale.value.UncheckedGet<float>();
    }
    if (!material.useSpecularWorkflow.isEmpty() &&
        material.useSpecularWorkflow.value.IsHolding<int>()) {
        result.useSpecularWorkflow = material.useSpecularWorkflow.value.UncheckedGet<int>() != 0;
    }
    if (!material.opacityThreshold.isEmpty() &&
        material.opacityThreshold.value.IsHolding<float>()) {
        float threshold = material.opacityThreshold.value.UncheckedGet<float>();
        if (threshold > 0.0f) {
            result.opacityThreshold = threshold;
        }
    }
    result.clearcoatModelsTransmissionTint = material.clearcoatModelsTransmissionTint;
    result.isUnlit = material.isUnlit;

    return result;
}

}
