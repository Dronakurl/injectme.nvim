describe("inspectme", function()
  -- before_each(function()
  --   require"stackmap"._clear()
  --
  --   -- Please don't have this mapping when we start.
  --   pcall(vim.keymap.del, "n", "asdfasdf")
  -- end)

  it("can be required", function()
    require("inspectme")
  end)
end)
