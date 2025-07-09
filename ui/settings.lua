local settings = {
    scale = 1,
}

settings.scale = os.getenv("SCALE") or 1

return settings
