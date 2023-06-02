import {Hook, makeHook} from 'phoenix_typed_hook';

function fail() {
  alert('This browser does not support Copy');
}

class Impl extends Hook {
  mounted() {
    const {el} = this;
    const {dataset} = el;
    const {target} = dataset;

    if (!target) {
      throw new Error('CopyToClipboardHook - target is required');
    }

    el.addEventListener('click', (e) => {
      e.preventDefault();
      const text = document.getElementById(target)?.innerText || '';

      if (!navigator.clipboard) {
        fail();
        return;
      }
      navigator.clipboard.writeText(text).then(
        function () {
          alert(`Copied! ${text}`);
        },
        function (err) {
          fail();
        }
      );
    });
  }
}

export const CopyToClipboardHook = makeHook(Impl);
