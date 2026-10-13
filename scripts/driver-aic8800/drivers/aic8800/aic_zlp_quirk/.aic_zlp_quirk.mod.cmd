savedcmd_aic_zlp_quirk/aic_zlp_quirk.mod := printf '%s\n'   aic_zlp_quirk.o | awk '!x[$$0]++ { print("aic_zlp_quirk/"$$0) }' > aic_zlp_quirk/aic_zlp_quirk.mod
