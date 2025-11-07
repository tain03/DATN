import { apiClient } from "./apiClient"

export interface UploadAudioResponse {
  audio_url: string
  object_name?: string
  content_type?: string
  size?: number
}

export const storageApi = {
  /**
   * Upload audio file directly to storage service
   * Uses multipart/form-data to upload file
   */
  uploadAudio: async (audioFile: File): Promise<string> => {
    const formData = new FormData()
    formData.append("file", audioFile)

    // Upload file directly to storage service
    const response = await apiClient.post<{
      success: boolean
      data: UploadAudioResponse
    }>("/storage/audio/upload", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    })

    return response.data.data.audio_url
  },
}

