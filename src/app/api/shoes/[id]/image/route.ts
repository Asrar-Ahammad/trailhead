import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { v4 as uuidv4 } from 'uuid';

const prisma = new PrismaClient();

const s3Client = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || '',
  },
});

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: shoeId } = await params;
    
    // Parse multipart form data
    const formData = await request.formData();
    const file = formData.get('image') as File | null;
    
    if (!file) {
      return NextResponse.json({ error: 'No image provided' }, { status: 400 });
    }

    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    const extension = file.type === 'image/png' ? 'png' : 'jpg';
    const fileName = `shoes/${shoeId}-${uuidv4()}.${extension}`;

    // Upload to Cloudflare R2
    const bucketName = process.env.R2_BUCKET_NAME || '';
    
    await s3Client.send(new PutObjectCommand({
      Bucket: bucketName,
      Key: fileName,
      Body: buffer,
      ContentType: file.type,
    }));

    // Construct the public URL
    const publicUrl = `${process.env.R2_PUBLIC_URL}/${fileName}`;

    // Update the shoe in Prisma
    const updatedShoe = await prisma.shoe.update({
      where: { id: shoeId },
      data: { imageUrl: publicUrl },
    });

    return NextResponse.json({ success: true, shoe: updatedShoe, imageUrl: publicUrl });
  } catch (error: any) {
    console.error('Error uploading shoe image:', error);
    return NextResponse.json({ error: error.message || 'Failed to upload image' }, { status: 500 });
  }
}
