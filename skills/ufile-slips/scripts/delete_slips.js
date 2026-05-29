/**
 * delete_slips.js
 * 
 * 这个脚本可以在浏览器控制台 (Console) 中运行，用来批量删除指定的 slips。
 * 
 * 用法:
 * 将整个脚本复制粘贴到浏览器的开发者工具控制台 (F12 -> Console) 中执行。
 * 
 * 示例:
 * deleteSlips(["T3: CIBC", "T3: TD Waterhouse"]);
 */

async function deleteSlips(typeOrNames) {
  const isArray = Array.isArray(typeOrNames);
  console.log(`开始准备删除: ${isArray ? typeOrNames.join(', ') : typeOrNames}`);

  // 1. 覆盖原生的 window.confirm
  const originalConfirm = window.confirm;
  window.confirm = () => true;

  const deleteOne = async (btn, name) => {
    console.log(`[${name}] 找到删除按钮，正在点击...`);
    btn.click();
    
    // 等待弹窗显示
    await new Promise(r => setTimeout(r, 800));
    
    // 2. 查找 DOM 中自定义的确认弹窗 (OK/Yes)
    const modalButtons = Array.from(document.querySelectorAll('button')).filter(b => {
      const text = (b.innerText || '').trim().toLowerCase();
      return text === 'ok' || text === 'yes';
    });
    
    const okBtn = modalButtons.reverse().find(b => b.offsetWidth > 0 || b.offsetHeight > 0);
    
    if (okBtn) {
      console.log(`[${name}] 找到确认按钮，点击 OK...`);
      okBtn.click();
      // 等待删除请求完成和 DOM 刷新
      await new Promise(r => setTimeout(r, 2000));
      return true;
    } else {
      console.log(`[${name}] 未找到自定义 OK 按钮，假设原生确认生效。`);
      await new Promise(r => setTimeout(r, 1500));
      return true;
    }
  };

  if (!isArray) {
    // 模式：删除所有指定类型的 (例如 "T3")
    const type = typeOrNames.toUpperCase();
    console.log(`正在执行批量删除所有 ${type} 类型...`);
    
    while (true) {
      // 每次循环重新查找，防止 DOM 引用失效
      const btns = Array.from(document.querySelectorAll('button[aria-label^="Remove Item."]'));
      const targetBtn = btns.find(b => b.getAttribute('aria-label').includes(type));
      
      if (!targetBtn) {
        console.log(`✅ 所有类型为 ${type} 的 slips 已删除。`);
        break;
      }
      
      const label = targetBtn.getAttribute('aria-label');
      await deleteOne(targetBtn, label);
    }
  } else {
    // 模式：删除指定的名称列表
    for (const name of typeOrNames) {
      const btn = document.querySelector(`button[aria-label="Remove Item. ${name}"]`);
      if (btn) {
        await deleteOne(btn, name);
      } else {
        console.warn(`[${name}] ❌ 未找到删除按钮。`);
      }
    }
  }
  
  window.confirm = originalConfirm;
  console.log('✅ 删除任务执行完毕。');
}

// ==========================================
// 在这里修改你要删除的 slips 列表，然后运行：
// deleteSlips(["T3: CIBC", "T3: TD Waterhouse"]);
// ==========================================
