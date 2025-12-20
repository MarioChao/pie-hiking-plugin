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

export type LightingConfigType = {
	Atmosphere: Atmosphere?,
	Lighting: LightingProperties?,
	PostProcessing: {PostEffect}?,
	Sky: Sky?,
	tweenDuration: number?,
}


---------- Return module ----------

return 1
