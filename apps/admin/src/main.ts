import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'

import App from './App.vue'
import router from './router'
import { setAuthErrorHandler } from './api/auth-events'
import { useAuthStore } from './stores/auth'
import './styles/index.scss'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)

setAuthErrorHandler((error) => {
  const destination = useAuthStore().handleApiError(error)
  if (destination === 'login' && router.currentRoute.value.path !== '/login')
    void router.replace('/login')
  if (destination === 'forbidden' && router.currentRoute.value.path !== '/403')
    void router.replace('/403')
})

app.use(router)
app.use(ElementPlus)

app.mount('#app')
