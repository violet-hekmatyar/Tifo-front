<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { useAuthStore } from '@/stores/auth'

const { user } = storeToRefs(useAuthStore())
</script>

<template>
  <section class="admin-page">
    <div class="admin-page__heading">
      <div>
        <p class="eyebrow">WORKSPACE</p>
        <h1>工作台</h1>
        <p>欢迎回来，{{ user?.nickname || user?.username }}。</p>
      </div>
      <el-tag type="success">{{ user?.roleType }}</el-tag>
    </div>
    <el-card shadow="never"
      ><el-result
        icon="success"
        title="F08 后台基础框架已完成"
        sub-title="管理员认证、权限守卫与后台布局已接通真实后端。"
    /></el-card>
    <el-card shadow="never" class="scope-card"
      ><template #header><strong>后续模块</strong></template>
      <p>F09：用户与内容管理；F10：足球数据维护；F11：文件管理。</p>
      <p>本页不展示虚构用户数、内容数、比赛数或趋势图。</p></el-card
    >
  </section>
</template>
