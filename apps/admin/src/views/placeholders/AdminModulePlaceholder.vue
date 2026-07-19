<script setup lang="ts">
defineProps<{ title: string; scope: string }>()
</script>
<template>
  <section class="admin-page">
    <h1>{{ title }}</h1>
    <el-empty description="本模块尚未开放"
      ><p>{{ scope }}</p>
      <p>F08 不展示假业务数据。</p></el-empty
    >
  </section>
</template>
