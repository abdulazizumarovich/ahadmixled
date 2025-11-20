package uz.iportal.axadmixled.data.remote.api

import retrofit2.http.*
import uz.iportal.axadmixled.domain.model.PlaylistDetail
import uz.iportal.axadmixled.domain.model.PlaylistsResponse

interface PlaylistApi {
    @GET("api/v1/admin/cloud/playlists")
    suspend fun getPlaylists(
        @Header("Authorization") token: String,
        @Query("sn_number") snNumber: String
    ): PlaylistsResponse

    @GET("api/v1/admin/cloud/playlists/{id}/")
    suspend fun getPlaylistDetail(
        @Header("Authorization") token: String,
        @Path("id") playlistId: Int
    ): PlaylistDetail
}
