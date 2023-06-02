import {Hook, makeHook} from 'phoenix_typed_hook';
import flatpickr from 'flatpickr';
import 'flatpickr/dist/flatpickr.css';

class Impl extends Hook {
  flatpickr: any;
  onOpenFn: any;

  mounted() {
    // onOpen/onClose are workarounds to prevent phx-click-away from firing in a modal

    const f: any = flatpickr(this.el, {
      enableTime: true,
      dateFormat: 'Z',
      altInput: true,
      altFormat: 'F j, Y @ h:i K',
      // defaultDate: 'today',
      // minDate: 'today',
      // maxDate: (new Date() as any).fp_incr(6),
      // minTime: '06:00',
      // maxTime: '22:00',
      minuteIncrement: 15,
      onOpen: (selectedDates: any, dateStr: any, instance: any) => {
        const fn = (e: Event) => {
          e.stopPropagation();
        };
        this.onOpenFn = fn;
        f.calendarContainer.parentElement.addEventListener('click', fn);
      },
      onClose: (selectedDates: any, dateStr: any, instance: any) => {
        f.calendarContainer.parentElement.removeEventListener('click', this.onOpenFn);
        this.onOpenFn = null;
      },
    });

    this.flatpickr = f;
  }
  destroyed(): void {
    if (this.onOpenFn) {
      this.flatpickr.calendarContainer.parentElement.removeEventListener('click', this.onOpenFn);
      this.onOpenFn = null;
    }

    this.flatpickr.destroy();
  }
}

export const FlatpickrHook = makeHook(Impl);
