--!strict
-- Types Module

---------- Types ----------

export type LightingProperties = {
	Ambient: Color3?,
	Brightness: number?,
	ColorShift_Bottom: Color3?,
	ColorShift_Top: Color3?,
	EnvironmentDiffuseScale: number?,
	EnvironmentSpecularScale: number?,
	ExposureCompensation: number?,
	FogColor: Color3?,
	FogEnd: number?,
	FogStart: number?,
	GeographicLatitude: number?,
	GlobalShadows: boolean?,
	OutdoorAmbient: Color3?,
	ShadowSoftness: number?,
	TimeOfDay: string?,
}

export type PostEffectTypes = {
	Bloom: BloomEffect?,
	Blur: BlurEffect?,
	ColorCorrection: ColorCorrectionEffect?,
	DepthOfField: DepthOfFieldEffect?,
	SunRays: SunRaysEffect?,
}

export type LightingConfigType = {
	Atmosphere: Atmosphere?,
	Lighting: LightingProperties?,
	PostProcessing: PostEffectTypes?,
	Sky: Sky?,
}


---------- Return module ----------
return 1
