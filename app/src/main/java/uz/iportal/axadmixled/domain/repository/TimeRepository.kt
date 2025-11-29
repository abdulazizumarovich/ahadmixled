package uz.iportal.axadmixled.domain.repository

import android.content.Context

interface TimeRepository {
    fun initialize(context: Context)
    fun getCurrentTimeMillis(): Long
}