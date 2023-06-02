import Cropper from 'cropperjs';

const PHX_UPLOAD_REF = 'data-phx-upload-ref';
const PHX_PRIVATE = 'phxPrivate';

// from phx dom.js
function putPrivate(el, key, value) {
  if (!el[PHX_PRIVATE]) {
    el[PHX_PRIVATE] = {};
  }
  el[PHX_PRIVATE][key] = value;
}

// return width/height that have the same aspect ratio as minWidth/minHeight
// that can contain srcWidth/srcHeight
function getFillDims(srcWidth, srcHeight, minWidth, minHeight) {
  const scale = Math.min((minWidth || srcWidth) / srcWidth, (minHeight || srcHeight) / srcHeight);
  // console.log('minWidth', minWidth);
  // console.log('minHeight', minHeight);
  // console.log('scale', scale);

  const dims = {
    width: srcWidth * scale,
    height: srcHeight * scale,
  };

  if (dims.width < minWidth) {
    dims.width = minWidth;
  }
  if (dims.height < minHeight) {
    dims.height = minHeight;
  }
  if (dims.width < srcWidth) {
    const ratio = srcWidth / dims.width;

    dims.width = srcWidth;
    dims.height *= ratio;
  }
  if (dims.height < srcHeight) {
    const ratio = srcHeight / dims.height;

    dims.height = srcHeight;
    dims.width *= ratio;
  }
  return dims;
}

function getNaturalCrop(image, relativeCrop) {
  const scaleX = image.naturalWidth / image.width;
  const scaleY = image.naturalHeight / image.height;

  return {
    ...relativeCrop,
    x: relativeCrop.x * scaleX,
    y: relativeCrop.y * scaleY,
    width: relativeCrop.width * scaleX,
    height: relativeCrop.height * scaleY,
  };
}

function getRelativeCrop(cropInfo, naturalCrop, aspectRatio) {
  const scaleX = cropInfo.prepImageDims.natural.width / cropInfo.prepImageDims.relative.width;
  const scaleY = cropInfo.prepImageDims.natural.height / cropInfo.prepImageDims.relative.height;

  const result = {
    ...naturalCrop,
    x: naturalCrop.x / scaleX,
    y: naturalCrop.y / scaleY,
    width: naturalCrop.width / scaleX,
    height: naturalCrop.height / scaleY,
  };

  // floating bounds checks - only fix small rounding errors that result from projection
  // between the smaller and larger coordinate systems.  real bounds errors can be left up
  // to the react-image-crop lib to handle

  const wDiff = result.x + result.width - cropInfo.prepImageDims.relative.width;

  if (wDiff > 0 && wDiff < 1.0) {
    result.width -= wDiff;
    result.height = result.width / aspectRatio;
  }
  const hDiff = result.y + result.height - cropInfo.prepImageDims.relative.height;

  if (hDiff > 0 && hDiff < 1.0) {
    result.height -= hDiff;
    result.width = result.height * aspectRatio;
  }

  return result;
}

// unused
function getCroppedImg(image, crop) {
  const canvas = document.createElement('canvas');

  const naturalCrop = getNaturalCrop(image, crop);

  canvas.width = Math.ceil(naturalCrop.width);
  canvas.height = Math.ceil(naturalCrop.height);
  const ctx = canvas.getContext('2d');

  ctx.fillStyle = 'rgba(255,255,255,0)';

  ctx.drawImage(image, naturalCrop.x, naturalCrop.y, naturalCrop.width, naturalCrop.height, 0, 0, canvas.width, canvas.height);

  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        const url = URL.createObjectURL(blob);
        const img = new Image();

        img.onload = () => resolve({canvas, img});
        img.onerror = reject;
        img.src = url;
      },
      'image/png',
      1
    );
  });
}

// unused
function getImgInDims(image, width, height) {
  const canvas = document.createElement('canvas');

  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');

  ctx.fillStyle = 'rgba(255,255,255,0)';

  ctx.drawImage(image, 0, 0, image.naturalWidth, image.naturalHeight, 0, 0, width, height);

  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        const url = URL.createObjectURL(blob);
        const img = new Image();

        img.onload = () => resolve({canvas, img});
        img.onerror = reject;
        img.src = url;
      },
      'image/png',
      1
    );
  });
}

function getPadOutImg(image, minWidth, minHeight) {
  const {naturalWidth, naturalHeight} = image;

  const dims = getFillDims(naturalWidth, naturalHeight, minWidth, minHeight);

  const canvas = document.createElement('canvas');

  canvas.width = dims.width;
  canvas.height = dims.height;

  const ctx = canvas.getContext('2d');

  ctx.fillStyle = 'rgba(255,255,255,0)';
  ctx.fillRect(0, 0, dims.width, dims.height);

  const destX = (dims.width - image.naturalWidth) / 2.0;
  const destY = (dims.height - image.naturalHeight) / 2.0;

  ctx.drawImage(image, 0, 0, image.naturalWidth, image.naturalHeight, destX, destY, image.naturalWidth, image.naturalHeight);

  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        const url = URL.createObjectURL(blob);
        const img = new Image();

        img.onload = () => resolve({canvas, img});
        img.onerror = reject;
        img.src = url;
      },
      'image/png',
      1
    );
  });
}

function getCropInfo(origImage, prepImage, requiredResolution, relativeCrop) {
  const naturalCrop = getNaturalCrop(prepImage, relativeCrop);
  const warnSmall = Math.ceil(requiredResolution.width) > Math.ceil(naturalCrop.width) || Math.ceil(requiredResolution.height) > Math.ceil(naturalCrop.height);
  const leftEdge = (prepImage.naturalWidth - origImage.naturalWidth) / 2.0;
  const rightEdge = leftEdge + origImage.naturalWidth;
  const topEdge = (prepImage.naturalHeight - origImage.naturalHeight) / 2.0;
  const bottomEdge = topEdge + origImage.naturalHeight;
  const imageExtents = {topEdge, rightEdge, bottomEdge, leftEdge};
  const hasPaddingHoriz = naturalCrop.x < leftEdge || naturalCrop.x + naturalCrop.width > rightEdge;
  const hasPaddingVert = naturalCrop.y < topEdge || naturalCrop.y + naturalCrop.height > bottomEdge;
  const hasPadding = hasPaddingHoriz || hasPaddingVert;
  const origImageDims = {
    natural: {
      width: origImage.naturalWidth,
      height: origImage.naturalHeight,
    },
    relative: {
      width: origImage.width,
      height: origImage.height,
    },
  };
  const prepImageDims = {
    natural: {
      width: prepImage.naturalWidth,
      height: prepImage.naturalHeight,
    },
    relative: {
      width: prepImage.width,
      height: prepImage.height,
    },
  };

  return {
    naturalCrop,
    relativeCrop,
    warnSmall,
    imageExtents,
    hasPadding,
    origImageDims,
    prepImageDims,
    requiredResolution,
  };
}

export const LiveImgEditor = {
  mounted() {
    this.output_type = this.el.getAttribute('data-output-type') || 'image/jpeg';
    this.ref = this.el.getAttribute('data-phx-entry-ref');
    this.requiredResolution = {width: parseInt(this.el.getAttribute('data-min-width')), height: parseInt(this.el.getAttribute('data-min-height'))};
    // console.log('requiredResolution', this.requiredResolution);
    this.aspectRatio = this.requiredResolution.width / this.requiredResolution.height;
    // console.log('aspectRatio', this.aspectRatio);
    this.inputEl = document.getElementById(this.el.getAttribute(PHX_UPLOAD_REF));
    let file;
    for (const f of this.inputEl.files) {
      if (f._phxRef === this.ref) {
        file = f;
        break;
      }
    }
    this.file = file;
    this.hookupDom();

    this.setup();
  },
  onDone(e) {
    const hook = this;
    e.preventDefault();

    const fillColor = hook.output_type === 'image/png' ? 'transparent' : 'white';

    const width = isNaN(this.requiredResolution.width) ? undefined : this.requiredResolution.width;
    const height = isNaN(this.requiredResolution.height) ? undefined : this.requiredResolution.height;

    this.cropper.getCroppedCanvas({fillColor, width, height, minHeight: height, minWidth: width, imageSmoothingEnabled: true, imageSmoothingQuality: 'high'}).toBlob(
      (blob) => {
        const newFile = new File([blob], `(cropped)${this.file.name}`, {type: hook.output_type});

        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(newFile);

        this.inputEl.files = dataTransfer.files;
        putPrivate(this.inputEl, 'files', Array.from(dataTransfer.files || []));
        this.inputEl.dispatchEvent(new Event('input', {bubbles: true}));
      },
      hook.output_type,
      1
    );
  },
  render() {
    this.snap_left.style.display = '';
    this.snap_right.style.display = '';
    this.snap_top.style.display = '';
    this.snap_bottom.style.display = '';
    if (this.canSnapHoriz) {
      this.snap_x.style.display = '';
    } else {
      this.snap_x.style.display = 'none';
    }
    if (this.canSnapVert) {
      this.snap_y.style.display = '';
    } else {
      this.snap_y.style.display = 'none';
    }
    this.snap_center.style.display = '';

    this.allow_upscale.style.display = '';

    this.status_small.style.display = 'none';
    this.status_padded.style.display = 'none';
    this.status_ok.style.display = 'none';

    if (this.cropInfo) {
      this.cropper.setData(this.cropInfo.relativeCrop);
      this.done.style.display = '';
      if (this.cropInfo.warnSmall) {
        this.status_small.style.display = '';
      } else if (this.cropInfo.hasPadding) {
        this.status_padded.style.display = '';
      } else {
        this.status_ok.style.display = '';
      }
    } else {
      this.done.style.display = 'none';
    }
  },
  async setup() {
    if (!this.file) return;
    const hook = this;
    const origUrl = URL.createObjectURL(this.file);
    const {requiredResolution} = this;

    const origImage = await new Promise((resolve, reject) => {
      const img = new Image();

      img.onload = () => {
        resolve(img);
      };
      img.onerror = reject;
      img.src = origUrl;
    });
    this.origImage = origImage;

    this.srcResult = await getPadOutImg(origImage, requiredResolution.width, requiredResolution.height);
    this.url = this.srcResult.img.src;

    const img = document.createElement('img');
    img.style.display = 'block';
    img.style.maxWidth = '100%';

    img.src = this.url;
    const prepImage = img;
    this.prepImage = prepImage;

    this.cropper_holder.appendChild(img);

    const cropper = new Cropper(img, {
      zoomable: false,
      zoomOnWheel: false,
      zoomOnTouch: false,
      scalable: false,
      rotatable: false,
      viewMode: 1,
      minWidth: requiredResolution.width,
      minHeight: requiredResolution.height,
      aspectRatio: this.aspectRatio,
      autoCrop: false,
      ready() {
        cropper.crop();

        const {prepImage, origImage, requiredResolution} = hook;
        const scaleX = prepImage.width / prepImage.naturalWidth;
        const scaleY = prepImage.height / prepImage.naturalHeight;
        const width = requiredResolution.width * scaleX;
        const height = requiredResolution.height * scaleY;
        const minWidth = width / 2.0;
        const minHeight = height / 2.0;
        const canSnapVert = origImage.height >= minHeight;
        const canSnapHoriz = origImage.width >= minWidth;
        const x = ((prepImage.naturalWidth - requiredResolution.width) / 2.0) * scaleX;
        const y = ((prepImage.naturalHeight - requiredResolution.height) / 2.0) * scaleY;

        const crop = {
          x,
          y,
          width,
          height,
        };

        const cropInfo = origImage && prepImage ? getCropInfo(origImage, prepImage, requiredResolution, crop) : null;
        hook.cropInfo = cropInfo;
        hook.canSnapHoriz = canSnapHoriz;
        hook.canSnapVert = canSnapVert;

        hook.render();
      },
      cropmove(event) {
        const data = cropper.getData();

        if (!hook.allowUpscale) {
          // prevents "small" warning" by not allowing it to happen
          if (data.width < requiredResolution.width) {
            event.preventDefault();
            data.width = requiredResolution.width;
          }

          if (data.height < requiredResolution.height) {
            event.preventDefault();
            data.height = requiredResolution.height;
          }
        }

        const cropInfo = origImage && prepImage ? getCropInfo(origImage, prepImage, requiredResolution, data) : null;
        hook.cropInfo = cropInfo;
        hook.render();
      },
    });

    this.cropper = cropper;
  },
  destroyed() {
    URL.revokeObjectURL(this.url);
  },
  hookupDom() {
    const {el} = this;

    this.snap_left = el.querySelector('[data-hook-el="snap_left"]');
    this.snap_left.addEventListener('click', this.snapLeft.bind(this));
    this.snap_left.style.display = 'none';

    this.snap_right = el.querySelector('[data-hook-el="snap_right"]');
    this.snap_right.addEventListener('click', this.snapRight.bind(this));
    this.snap_right.style.display = 'none';

    this.snap_top = el.querySelector('[data-hook-el="snap_top"]');
    this.snap_top.addEventListener('click', this.snapTop.bind(this));
    this.snap_top.style.display = 'none';

    this.snap_bottom = el.querySelector('[data-hook-el="snap_bottom"]');
    this.snap_bottom.addEventListener('click', this.snapBottom.bind(this));
    this.snap_bottom.style.display = 'none';

    this.snap_x = el.querySelector('[data-hook-el="snap_x"]');
    this.snap_x.addEventListener('click', this.snapX.bind(this));
    this.snap_x.style.display = 'none';

    this.snap_y = el.querySelector('[data-hook-el="snap_y"]');
    this.snap_y.addEventListener('click', this.snapY.bind(this));
    this.snap_y.style.display = 'none';

    this.snap_center = el.querySelector('[data-hook-el="snap_center"]');
    this.snap_center.addEventListener('click', this.snapCenter.bind(this));
    this.snap_center.style.display = 'none';

    this.allow_upscale = el.querySelector('[data-hook-el="allow_upscale"]');
    this.allow_upscale.addEventListener('change', this.onAllowUpscaleChange.bind(this));
    this.allow_upscale.style.display = 'none';

    this.done = el.querySelector('[data-hook-el="done"]');
    this.done.addEventListener('click', this.onDone.bind(this));
    this.done.style.display = 'none';

    this.status_small = el.querySelector('[data-hook-el="status_small"]');
    this.status_small.style.display = 'none';
    this.status_padded = el.querySelector('[data-hook-el="status_padded"]');
    this.status_padded.style.display = 'none';
    this.status_ok = el.querySelector('[data-hook-el="status_ok"]');
    this.status_ok.style.display = 'none';

    this.cropper_holder = el.querySelector('[data-hook-el="cropper_holder"]');
  },

  onAllowUpscaleChange(e) {
    this.allowUpscale = e.target.checked;
    e.target.blur();
    this.render();
  },

  snapLeft(e) {
    e.preventDefault();
    const {cropInfo, origImage, prepImage} = this;
    const {requiredResolution} = this;

    if (!cropInfo || !prepImage || !origImage) {
      return;
    }

    const naturalCrop = {
      ...cropInfo.naturalCrop,
      x: cropInfo.imageExtents.leftEdge,
    };

    if (naturalCrop.x + naturalCrop.width > prepImage.naturalWidth) {
      const diff = naturalCrop.x + naturalCrop.width - prepImage.naturalWidth;

      // shrink
      naturalCrop.width -= diff;
      naturalCrop.height = naturalCrop.width / this.aspectRatio;
    }

    const newCrop = getRelativeCrop(cropInfo, naturalCrop, this.aspectRatio);

    const newCropInfo = getCropInfo(origImage, prepImage, requiredResolution, newCrop);

    this.cropInfo = newCropInfo;
    this.render();
  },

  snapRight(e) {
    e.preventDefault();
    const {cropInfo, origImage, prepImage} = this;
    const {requiredResolution} = this;

    if (!cropInfo || !prepImage || !origImage) {
      return;
    }

    const naturalCrop = {
      ...cropInfo.naturalCrop,
      x: cropInfo.imageExtents.rightEdge - cropInfo.naturalCrop.width,
    };

    if (naturalCrop.x < 0) {
      const diff = -naturalCrop.x;

      naturalCrop.x = 0;
      // shrink
      naturalCrop.width -= diff;
      naturalCrop.height = naturalCrop.width / this.aspectRatio;
    }
    const newCrop = getRelativeCrop(cropInfo, naturalCrop, this.aspectRatio);

    const newCropInfo = getCropInfo(origImage, prepImage, requiredResolution, newCrop);

    this.cropInfo = newCropInfo;
    this.render();
  },

  snapX(e) {
    e.preventDefault();
    const {cropInfo, origImage, prepImage} = this;
    const {requiredResolution} = this;

    if (!cropInfo || !prepImage || !origImage) {
      return;
    }

    const naturalCrop = {
      ...cropInfo.naturalCrop,
      x: cropInfo.imageExtents.leftEdge,
      width: cropInfo.imageExtents.rightEdge - cropInfo.imageExtents.leftEdge,
    };

    naturalCrop.height = naturalCrop.width / this.aspectRatio;

    if (naturalCrop.y + naturalCrop.height > prepImage.naturalHeight) {
      naturalCrop.y = prepImage.naturalHeight - naturalCrop.height;
    }

    const newCrop = getRelativeCrop(cropInfo, naturalCrop, this.aspectRatio);

    const newCropInfo = getCropInfo(origImage, prepImage, requiredResolution, newCrop);

    this.cropInfo = newCropInfo;
    this.render();
  },

  snapTop(e) {
    e.preventDefault();
    const {cropInfo, origImage, prepImage} = this;
    const {requiredResolution} = this;

    if (!cropInfo || !prepImage || !origImage) {
      return;
    }

    const naturalCrop = {
      ...cropInfo.naturalCrop,
      y: cropInfo.imageExtents.topEdge,
    };

    if (naturalCrop.y + naturalCrop.height > prepImage.naturalHeight) {
      naturalCrop.height = prepImage.naturalHeight - naturalCrop.y;
      naturalCrop.width = naturalCrop.height * this.aspectRatio;
    }

    if (naturalCrop.x + naturalCrop.width > prepImage.naturalWidth) {
      naturalCrop.width = prepImage.naturalWidth - naturalCrop.x;
      naturalCrop.height = naturalCrop.width / this.aspectRatio;
    }

    const newCrop = getRelativeCrop(cropInfo, naturalCrop, this.aspectRatio);

    const newCropInfo = getCropInfo(origImage, prepImage, requiredResolution, newCrop);

    this.cropInfo = newCropInfo;
    this.render();
  },

  snapBottom(e) {
    e.preventDefault();
    const {cropInfo, origImage, prepImage} = this;
    const {requiredResolution} = this;

    if (!cropInfo || !prepImage || !origImage) {
      return;
    }

    const naturalCrop = {
      ...cropInfo.naturalCrop,
      y: cropInfo.imageExtents.bottomEdge - cropInfo.naturalCrop.height,
    };

    if (naturalCrop.y < 0) {
      const diff = -naturalCrop.y;

      naturalCrop.y = 0;
      // shrink
      naturalCrop.height -= diff;
      naturalCrop.width = naturalCrop.height * this.aspectRatio;
    }

    if (naturalCrop.x + naturalCrop.width > prepImage.naturalWidth) {
      naturalCrop.width = prepImage.naturalWidth - naturalCrop.x;
      const curHeight = naturalCrop.height;

      naturalCrop.height = naturalCrop.width / this.aspectRatio;
      naturalCrop.y += curHeight;
    }

    const newCrop = getRelativeCrop(cropInfo, naturalCrop, this.aspectRatio);

    const newCropInfo = getCropInfo(origImage, prepImage, requiredResolution, newCrop);

    this.cropInfo = newCropInfo;
    this.render();
  },

  snapY(e) {
    e.preventDefault();
    const {cropInfo, origImage, prepImage} = this;
    const {requiredResolution} = this;

    if (!cropInfo || !prepImage || !origImage) {
      return;
    }

    const naturalCrop = {
      ...cropInfo.naturalCrop,
      y: cropInfo.imageExtents.topEdge,
      height: cropInfo.imageExtents.bottomEdge - cropInfo.imageExtents.topEdge,
    };

    naturalCrop.width = naturalCrop.height * this.aspectRatio;

    if (naturalCrop.x + naturalCrop.width > prepImage.naturalWidth) {
      naturalCrop.x = prepImage.naturalWidth - naturalCrop.width;
    }

    if (naturalCrop.x < 0) {
      const diff = -naturalCrop.x;

      naturalCrop.x = 0;
      // shrink
      naturalCrop.width -= diff;
      naturalCrop.height = naturalCrop.width / this.aspectRatio;
    }

    const newCrop = getRelativeCrop(cropInfo, naturalCrop, this.aspectRatio);

    const newCropInfo = getCropInfo(origImage, prepImage, requiredResolution, newCrop);

    this.cropInfo = newCropInfo;
    this.render();
  },

  snapCenter(e) {
    e.preventDefault();
    const {cropInfo, origImage, prepImage} = this;
    const {requiredResolution} = this;

    if (!cropInfo || !prepImage || !origImage) {
      return;
    }

    const naturalCrop = {
      ...cropInfo.naturalCrop,
      x: (prepImage.naturalWidth - cropInfo.naturalCrop.width) / 2.0,
      y: (prepImage.naturalHeight - cropInfo.naturalCrop.height) / 2.0,
    };

    const newCrop = getRelativeCrop(cropInfo, naturalCrop, this.aspectRatio);

    const newCropInfo = getCropInfo(origImage, prepImage, requiredResolution, newCrop);

    this.cropInfo = newCropInfo;
    this.render();
  },
};
