# todo

- [x] implement middleware registering with :use
  - [ ] remove logger
  - [ ] smooth docs
  - [ ] refactor request response with local func
- [ ] if there's middleware but no handler => 404 (currently 500)
- [ ] test middleware with wildcard
- [ ] all error should return type text/plain and the status statusmsg in body
