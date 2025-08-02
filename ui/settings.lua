local settings = {
    scale = 1,
}

settings.scale = tonumber(os.getenv("SCALE")) or 1

return settings
