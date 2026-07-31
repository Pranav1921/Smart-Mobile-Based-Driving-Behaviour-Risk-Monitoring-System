import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { StorageProvider, UploadResult } from './storage.provider';
import { logger } from '../config/logger';

export class LocalProvider implements StorageProvider {
  private uploadDir: string;

  constructor() {
    this.uploadDir = path.resolve(process.env.LOCAL_STORAGE_DIR || './uploads');
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string
  ): Promise<UploadResult> {
    try {
      const targetFolder = path.join(this.uploadDir, folder);
      if (!fs.existsSync(targetFolder)) {
        fs.mkdirSync(targetFolder, { recursive: true });
      }

      const fileExt = path.extname(file.originalname);
      const fileName = `${uuidv4()}${fileExt}`;
      const relativePath = path.join(folder, fileName);
      const absolutePath = path.join(targetFolder, fileName);

      if (file.buffer) {
        await fs.promises.writeFile(absolutePath, file.buffer);
      } else if (file.path) {
        await fs.promises.copyFile(file.path, absolutePath);
        await fs.promises.unlink(file.path);
      } else {
        throw new Error('Multer file contains no data buffer or path');
      }

      // Replace backslashes for clean URL paths on Windows environments
      const relativeUrl = `/uploads/${relativePath}`.replace(/\\/g, '/');
      logger.debug(`File uploaded locally: ${relativeUrl}`);

      return {
        url: relativeUrl,
        publicId: relativeUrl,
      };
    } catch (error) {
      logger.error('Failed local file upload:', error);
      throw error;
    }
  }

  async deleteFile(publicId: string): Promise<void> {
    try {
      // Remove prefix "/uploads/"
      const relativePath = publicId.replace(/^\/uploads\//, '');
      const absolutePath = path.join(this.uploadDir, relativePath);
      if (fs.existsSync(absolutePath)) {
        await fs.promises.unlink(absolutePath);
        logger.debug(`Deleted local file: ${absolutePath}`);
      }
    } catch (error) {
      logger.error(`Failed to delete local file: ${publicId}`, error);
    }
  }
}
