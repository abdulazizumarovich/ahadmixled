package uz.iportal.axadmixled.domain.model

import com.google.gson.annotations.SerializedName

data class AuthTokenResponse(

	@field:SerializedName("access")
	val access: String? = null,

	@field:SerializedName("role")
	val role: String? = null,

	@field:SerializedName("refresh")
	val refresh: String? = null,

	@field:SerializedName("expire_in")
	val expireIn: String? = null,

	@field:SerializedName("refresh_expire")
	val refreshExpire: String? = null
)
