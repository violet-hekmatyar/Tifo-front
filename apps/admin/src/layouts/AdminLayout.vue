<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'

import AdminSidebar from '@/components/admin/AdminSidebar.vue'
import AdminTopbar from '@/components/admin/AdminTopbar.vue'
import { useAuthStore } from '@/stores/auth'

const collapsed = ref(false)
const auth = useAuthStore()
const { user } = storeToRefs(auth)
const router = useRouter()

function logout(): void {
  auth.logout()
  void router.replace('/login')
}
</script>

<template>
  <div v-if="user" class="admin-layout" :class="{ 'admin-layout--collapsed': collapsed }">
    <AdminSidebar :collapsed="collapsed" />
    <AdminTopbar
      :collapsed="collapsed"
      :user="user"
      @toggle="collapsed = !collapsed"
      @logout="logout"
    />
    <main class="admin-layout__content"><RouterView /></main>
  </div>
</template>
