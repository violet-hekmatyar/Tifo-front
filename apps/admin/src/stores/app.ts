import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

export const useAppStore = defineStore('app', () => {
  const applicationName = ref('南看台管理后台')
  const initialized = computed(() => true)

  return { applicationName, initialized }
})
