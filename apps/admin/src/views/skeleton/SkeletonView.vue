<script setup lang="ts">
import { storeToRefs } from 'pinia'

import AppStatusCard from '@/components/common/AppStatusCard.vue'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const { applicationName } = storeToRefs(appStore)
</script>

<template>
  <main class="skeleton-view">
    <AppStatusCard :title="applicationName" status="Vue admin initialized" />
  </main>
</template>
