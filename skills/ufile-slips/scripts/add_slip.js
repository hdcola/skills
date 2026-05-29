/**
 * add_slip.js
 * 
 * 这个脚本可以在浏览器控制台 (Console) 中运行，用来自动新增 T3 或 T5 slip。
 * 
 * 用法:
 * 将整个脚本复制粘贴到浏览器的开发者工具控制台 (F12 -> Console) 中执行。
 * 
 * 示例:
 * addSlip("T3"); // 新增一个空的 T3
 * addSlip("T5"); // 新增一个空的 T5
 */

async function addSlip(type) {
  const normalizedType = type.toUpperCase();
  if (normalizedType !== "T3" && normalizedType !== "T5") {
    console.error("❌ 错误: type 必须是 'T3' 或 'T5'");
    return;
  }

  console.log(`🚀 开始准备新增 ${normalizedType} slip...`);

  // 辅助函数：查找 Add 按钮
  const label = normalizedType === "T3" ? "Add Item. T3 - Trust income" : "Add Item. T5 - Investment income";
  const getAddBtn = () => document.querySelector(`button[aria-label="${label}"]`);

  // 1. 检查是否已经在汇总页
  let addBtn = getAddBtn();
  
  if (!addBtn) {
    console.log("正在尝试导航到汇总页...");
    // 找到左侧菜单按钮。UFile 中这是一个 DIV[role="button"]
    const menuBtns = Array.from(document.querySelectorAll('[role="button"], button'));
    const menuBtn = menuBtns.find(el => 
      el.innerText && el.innerText.includes("Interest, investment income and carrying charges") &&
      (el.classList.contains("tocItemMainButton") || el.tagName === "BUTTON")
    );

    if (menuBtn) {
      console.log("点击左侧菜单...");
      menuBtn.click();
      
      // 2. 等待 Add 按钮出现 (最多等待 5 秒)
      console.log("等待 Add 按钮加载...");
      for (let i = 0; i < 10; i++) {
        await new Promise(r => setTimeout(r, 500));
        addBtn = getAddBtn();
        if (addBtn) {
          console.log(`第 ${i+1} 次尝试找到按钮。`);
          break;
        }
      }
    } else {
      console.warn("⚠️ 未找到左侧菜单按钮。");
    }
  }

  // 3. 点击 Add 按钮
  if (addBtn) {
    console.log(`找到 ${normalizedType} 的 Add 按钮，正在点击...`);
    addBtn.click();
    console.log(`✅ 已点击新增 ${normalizedType}。`);
  } else {
    console.error(`❌ 未找到 ${normalizedType} 的 Add 按钮。请确认是否在正确页面。`);
  }
}

// ==========================================
// 在这里修改你要新增的类型，然后运行：
// addSlip("T3"); 
// ==========================================
