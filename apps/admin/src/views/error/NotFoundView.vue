<template>
  <main class="not-found-view">
    <el-result icon="warning" title="404" sub-title="页面不存在">
      <template #extra>
        <RouterLink to="/">返回基础骨架</RouterLink>
      </template>
    </el-result>
  </main>
</template>
