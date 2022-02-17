local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

local File = require('vfiler/items/file')

local Directory = {}

local function new_item(stat)
  local item
  if stat.type == fs.types.DIRECTORY then
    item = Directory.new(stat)
  elseif stat.type == fs.types.FILE then
    item = File.new(stat)
  else
    core.message.warning('Unknown "%s" file type. (%s)', stat.type, stat.path)
  end
  return item
end

function Directory.new(stat)
  local Item = require('vfiler/items/item')
  local self = core.inherit(Directory, Item, stat)
  self.children = nil
  self.opened = false
  self.type = self.is_link and 'L' or 'D'
  return self
end

function Directory:add(item)
  if not self.children then
    self.children = {}
  end
  self:_remove(item)
  self:_add(item)
end

function Directory:close()
  self.children = nil
  self.opened = false
end

function Directory:copy(destpath)
  if self.is_link then
    fs.copy_file(self.path, destpath)
  else
    fs.copy_directory(self.path, destpath)
  end

  if not core.path.exists(destpath) then
    return nil
  end
  return Directory.new(fs.stat(destpath))
end

function Directory:create_directory(name)
  local dirpath = core.path.join(self.path, name)
  local directory = Directory.create(dirpath)
  if not core.path.is_directory(dirpath) then
    return nil
  end
  self:add(directory)
  return directory
end

function Directory:create_file(name)
  local filepath = core.path.join(self.path, name)
  local file = File.create(filepath)
  if not core.path.filereadable(filepath) then
    return nil
  end
  self:add(file)
  return file
end

function Directory:move(destpath)
  if self:_move(destpath) then
    return Directory.new(fs.stat(destpath))
  end
  return nil
end

function Directory:open(recursive)
  self.children = {}
  for stat in fs.scandir(self.path) do
    local item = new_item(stat)
    self:_add(item)
    if recursive and item.is_directory then
      item:open(recursive)
    end
  end
  self.opened = true
end

function Directory:_add(item)
  item.parent = self
  item.level = self.level + 1
  table.insert(self.children, item)
end

function Directory:_remove(item)
  local pos = nil
  for i, child in ipairs(self.children) do
    if
      (child.name == item.name)
      and (child.is_directory == item.is_directory)
    then
      pos = i
      break
    end
  end
  if pos then
    table.remove(self.children, pos)
  end
end

return Directory
