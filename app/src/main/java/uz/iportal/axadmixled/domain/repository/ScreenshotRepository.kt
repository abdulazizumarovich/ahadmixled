package uz.iportal.axadmixled.domain.repository

import java.io.File

interface ScreenshotRepository {
    suspend fun uploadScreenshot(mediaId: Int, screenshotFile: File): Result<Unit>
}
