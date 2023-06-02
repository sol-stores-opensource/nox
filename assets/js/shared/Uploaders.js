import * as UpChunk from '@mux/upchunk';

const Uploaders = {};

Uploaders.UpChunk = function (entries, onViewError) {
  entries.forEach((entry) => {
    // create the upload session with UpChunk
    let {
      file,
      meta: {entrypoint},
    } = entry;
    let upload = UpChunk.createUpload({endpoint: entrypoint, file});

    // stop uploading in the event of a view error
    onViewError(() => upload.pause());

    // upload error triggers LiveView error
    upload.on('error', (e) => entry.error(e.detail.message));

    // notify progress events to LiveView
    upload.on('progress', (e) => {
      if (e.detail < 100) {
        entry.progress(e.detail);
      }
    });

    // success completes the UploadEntry
    upload.on('success', () => entry.progress(100));
  });
};

export {Uploaders};
