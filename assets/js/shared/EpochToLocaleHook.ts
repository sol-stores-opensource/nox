import {Hook, makeHook} from 'phoenix_typed_hook';

class Impl extends Hook {
  run() {
    const epoch = parseInt(this.el.dataset.epochms || '0');
    const date = new Date(epoch);
    this.el.innerText = date.toLocaleString();
  }
  mounted(): void {
    this.run();
  }
  updated(): void {
    this.run();
  }
}

export const EpochToLocaleHook = makeHook(Impl);
