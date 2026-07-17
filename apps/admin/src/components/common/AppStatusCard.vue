<script setup lang="ts">
defineProps<{
  title: string
  status: string
}>()
</script>

<template>
  <el-card class="status-card" shadow="never">
    <template #header>
      <div class="status-card__header">
        <strong>{{ title }}</strong>
        <el-tag type="success" effect="light">F01 基础骨架</el-tag>
      </div>
    </template>
    <p>{{ status }}</p>
  </el-card>
</template>

<style scoped lang="scss">
.status-card {
  width: min(100%, 560px);

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }
}
</style>
