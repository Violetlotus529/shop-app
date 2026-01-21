# Order State Machine

pending → paid → processing → shipped → completed
processing → canceled

禁止:
- shipped以降はcanceled不可