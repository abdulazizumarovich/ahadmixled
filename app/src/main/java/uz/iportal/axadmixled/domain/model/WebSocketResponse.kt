package uz.iportal.axadmixled.domain.model

import com.google.gson.annotations.SerializedName

data class WebSocketResponse(

	@field:SerializedName("monitor_id")
	val monitorId: String,

	@field:SerializedName("type")
	val type: String,

	@field:SerializedName("message")
	val message: String,

	@field:SerializedName("timestamp")
	val timestamp: String
)
