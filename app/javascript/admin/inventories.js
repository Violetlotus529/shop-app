document.addEventListener("turbo:load", () => {  try {
  const tbody = document.getElementById("inventories-body")
  if (!tbody) return

  const saveBtn = document.getElementById("save-inventories")
  const form = document.getElementById("inventory-filters")
  const paginationEl = document.getElementById("pagination")
  const editToggle = document.getElementById("inventory-edit-toggle")

  function setEditing(on) {
    const inputs = tbody.querySelectorAll("input[data-variant-id]")
    inputs.forEach(input => { input.disabled = !on })
    if (saveBtn) saveBtn.style.display = on ? "" : "none"
    if (!on && saveBtn) saveBtn.disabled = true
  }

  function renderRows(variants) {
    tbody.innerHTML = ""
    variants.forEach(v => {
      const tr = document.createElement("tr")
      tr.innerHTML = `
        <td>${v.product_name}</td>
        <td>${v.color}</td>
        <td>${v.size}</td>
        <td>
          <input
            type="number"
            value="${v.stock}"
            data-variant-id="${v.id}"
            data-original-stock="${v.stock}"
            min="0"
            step="1"
            disabled
          >
        </td>
      `
      tbody.appendChild(tr)
    })

    // 再描画後に編集状態を反映
    setEditing(!!(editToggle && editToggle.checked))

  }

  function collectUpdates() {
    const updates = []
    const inputs = tbody.querySelectorAll("input[data-variant-id]")

    inputs.forEach(input => {
      const original = input.dataset.originalStock
      const current = input.value
      if (original !== current) {
        updates.push({ id: Number(input.dataset.variantId), stock: Number(current) })
      }
    })
    return updates
  }

  function confirmDiscardIfDirty() {
    const dirty = collectUpdates().length > 0
    if (!dirty) return true
    return confirm("未保存の変更があります。破棄して移動しますか？")
  }

  function renderPagination(pagination, currentParams) {
    if (!paginationEl) return
    const { current_page, total_pages } = pagination
    paginationEl.innerHTML = ""
    if (total_pages <= 1) return

    const prev = document.createElement("button")
    prev.type = "button"
    prev.textContent = "Prev"
    prev.disabled = current_page <= 1
    prev.addEventListener("click", () => {
      if (!confirmDiscardIfDirty()) return
      currentParams.set("page", String(current_page - 1))
      loadInventories(currentParams)
    })

    const next = document.createElement("button")
    next.type = "button"
    next.textContent = "Next"
    next.disabled = current_page >= total_pages
    next.addEventListener("click", () => {
      if (!confirmDiscardIfDirty()) return
      currentParams.set("page", String(current_page + 1))
      loadInventories(currentParams)
    })

    const info = document.createElement("span")
    info.textContent = ` Page ${current_page} / ${total_pages} `

    paginationEl.appendChild(prev)
    paginationEl.appendChild(info)
    paginationEl.appendChild(next)
  }

  async function loadInventories(params) {
    const qs = params.toString()
    const url = `/admin/api/inventories${qs ? `?${qs}` : ""}`

    const res = await fetch(url)
    const data = await res.json()

    renderRows(data.variants)
    if (data.pagination) renderPagination(data.pagination, params)

    history.replaceState(null, "", `${location.pathname}${qs ? `?${qs}` : ""}`)
  }

  function syncFormFromQuery(params) {
    if (!form) return

    const esc = (s) => (window.CSS && CSS.escape ? CSS.escape(s) : s)

    for (const [key, value] of params.entries()) {
      const el = form.querySelector(`[name="${esc(key)}"]`)
      if (el) el.value = value
    }
  }
  // 編集トグル
  if (editToggle) {
    editToggle.checked = false
    setEditing(false)

    editToggle.addEventListener("change", () => {
      if (!editToggle.checked) {
        // ON→OFFで未保存があれば確認、破棄なら元に戻す
        if (!confirmDiscardIfDirty()) {
          editToggle.checked = true
          return
        }
        // 破棄：表示値を original に戻す
        tbody.querySelectorAll("input[data-variant-id]").forEach(input => {
          input.value = input.dataset.originalStock
        })
      }
      setEditing(editToggle.checked)
    })
  }

  // フィルタ
  if (form) {
    form.addEventListener("submit", (e) => {
      e.preventDefault()
      if (!confirmDiscardIfDirty()) return

      const params = new URLSearchParams(new FormData(form))
      params.set("page", "1")
      loadInventories(params)
    })
  }

  // 入力変更で保存ボタン有効化
  tbody.addEventListener("input", (e) => {
    const input = e.target
    if (!(input instanceof HTMLInputElement)) return
    if (!input.matches("input[data-variant-id]")) return
    if (!editToggle || !editToggle.checked) return

    if (saveBtn) saveBtn.disabled = collectUpdates().length === 0
  })

  // 保存（variantsで送る）
  if (saveBtn) {
    saveBtn.addEventListener("click", async () => {
      const variants = collectUpdates()

      if (variants.length === 0) {
        alert("変更はありません")
        return
      }

      // 最低限バリデーション
      if (variants.some(v => !Number.isInteger(v.stock) || v.stock < 0)) {
        alert("在庫数は0以上の整数で入力してください")
        return
      }

      try {
        const res = await fetch("/admin/api/inventories/bulk_update", {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ variants })
        })

        const json = await res.json().catch(() => ({}))
        if (!res.ok) throw json

        // 保存成功後、original を更新して変更検知をリセット
        const inputs = tbody.querySelectorAll("input[data-variant-id]")
        inputs.forEach(input => { input.dataset.originalStock = input.value })

        saveBtn.disabled = true
        alert(`更新件数: ${json.updated_count}`)
      } catch (err) {
        alert(err.message || err.error || "保存に失敗しました")
      }
    })
  }

  const initialParams = new URLSearchParams(location.search)
  syncFormFromQuery(initialParams)
  loadInventories(initialParams)
  } catch (e) {
    console.error("[inventories] crashed", e)
    alert("inventories.js crashed (see console)")
  }
})