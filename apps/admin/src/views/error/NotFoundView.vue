<template>
  <main class="not-found-view">
    <el-result icon="warning" title="404" sub-title="页面不存在">
      <template #extra>
        <RouterLink to="/admin/dashboard">返回工作台</RouterLink>
      </template>
    </el-result>
  </main>
</template>
