# todo

- [x] implement middleware registering with :use
  - [x] remove logger
  - [x] smooth docs
  - [x] refactor request response with local func
- [x] if there's middleware but no handler => 404 (currently 500)
- [ ] test middleware with wildcard
- [ ] all error should return type text/plain and the status statusmsg in body

- [x] : logger
- [ ] : basic auth
- [ ] : JWT auth
- [ ] : renderer
- [ ] : prettyprint
- [ ] : static
  - maybe that's why it is a middleware

```ts

////////////////////////////////////////
//////                            //////
//////          Routes            //////
//////                            //////
////////////////////////////////////////

export interface RouterRoute {
  path: string
  method: string
  handler: H
}


////////////////////////////////////////
//////                            //////
//////          Handlers          //////
//////                            //////
////////////////////////////////////////

export type Next = () => Promise<void>

export type HandlerResponse<O> = Response | TypedResponse<O> | Promise<Response | TypedResponse<O>>

export type Handler<
  E extends Env = any,
  P extends string = any,
  I extends Input = BlankInput,
  R extends HandlerResponse<any> = any
> = (c: Context<E, P, I>, next: Next) => R

export type MiddlewareHandler<
  E extends Env = any,
  P extends string = string,
  I extends Input = {}
> = (c: Context<E, P, I>, next: Next) => Promise<Response | void>
