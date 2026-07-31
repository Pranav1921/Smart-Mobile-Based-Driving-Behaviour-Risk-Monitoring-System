import { v2 as cloudinary } from 'cloudinary';
import { StorageProvider, UploadResult } from './storage.provider';
import { LocalProvider } from './local.provider';
import { logger } from '../config/logger';

export class CloudinaryProvider implements StorageProvider {
  private fallback: LocalProvider | null = null;
  private isConfigured = false;

  constructor() {
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
      });
      this.isConfigured = true;
      logger.info('Cloudinary storage provider initialized.');
    } else {
      logger.warn(
        'Cloudinary credentials not provided. Falling back to local filesystem storage.'
      );
      this.fallback = new LocalProvider();
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string
  ): Promise<UploadResult> {
    if (!this.isConfigured) {
      return this.fallback!.uploadFile(file, folder);
    }

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder: `fleetguard/${folder}` },
        (error, result) => {
          if (error) {
            logger.error('Cloudinary upload stream failed:', error);
            reject(error);
          } else if (result) {
            resolve({
              url: result.secure_url,
              publicId: result.public_id,
            });
          } else {
            reject(new Error('Cloudinary response data is undefined'));
          }
        }
      );

      if (file.buffer) {
        uploadStream.end(file.buffer);
      } else {
        reject(
          new Error('Cloudinary upload stream requires memory storage buffer')
        );
      }
    });
  }

  async deleteFile(publicId: string): Promise<void> {
    if (!this.isConfigured) {
      await this.fallback!.deleteFile(publicId);
      return;
    }

    try {
      await cloudinary.uploader.destroy(publicId);
      logger.debug(`Deleted Cloudinary public asset: ${publicId}`);
    } catch (error) {
      logger.error(`Failed to delete Cloudinary asset: ${publicId}`, error);
    }
  }
}
