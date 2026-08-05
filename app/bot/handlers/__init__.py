from aiogram import Router

from app.bot.handlers.attend import router as attend_router
from app.bot.handlers.start import router as start_router
from app.bot.handlers.today import router as today_router

main_router = Router()
main_router.include_router(start_router)
main_router.include_router(today_router)
main_router.include_router(attend_router)
