import {Hook, makeHook} from 'phoenix_typed_hook';

class Impl extends Hook {
  mounted() {
    this.el.style.backgroundColor = 'green';
    this.handleEvent('foo', (payload) => {});
  }
}

export const MyHook = makeHook(Impl);
