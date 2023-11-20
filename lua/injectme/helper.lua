M = {}
M.compareStrings = function(str1, str2)
  -- Remove whitespaces from both strings
  str1 = string.gsub(str1, "%s+", "")
  str2 = string.gsub(str2, "%s+", "")

  -- Compare the two strings
  if str1 == str2 then
    return true
  else
    return false
  end
end

return M
