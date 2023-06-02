const html_tag = document.getElementById('html_tag');

export const ModalHook = {
  mounted() {
    html_tag.classList.add('is-clipped');
  },
  destroyed() {
    html_tag.classList.remove('is-clipped');
  },
};
