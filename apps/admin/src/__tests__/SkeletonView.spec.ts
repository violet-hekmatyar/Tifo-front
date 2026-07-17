import ElementPlus from 'element-plus'
import { createPinia } from 'pinia'
import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import SkeletonView from '@/views/skeleton/SkeletonView.vue'

describe('SkeletonView', () => {
  it('renders the F01 admin skeleton', () => {
    const wrapper = mount(SkeletonView, {
      global: {
        plugins: [createPinia(), ElementPlus],
      },
    })

    expect(wrapper.text()).toContain('南看台管理后台')
    expect(wrapper.text()).toContain('Vue admin initialized')
    expect(wrapper.find('.el-card').exists()).toBe(true)
  })
})
