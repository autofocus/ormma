package com.ormma.controller;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.content.Context;
import android.os.StatFs;

import com.ormma.view.OrmmaView;

public class OrmmaAssetController extends OrmmaController{
	public OrmmaAssetController(OrmmaView adView, Context c) {
		super(adView, c);
	}

	public void addAsset(String alias, String url) {
		HttpEntity entity = getHttpEntity(url);
		try {
			writeToDisk(entity, alias);
			String str = "javascript:OrmmaAdController.addedAsset('" + alias + "' )";
			mOrmmaView.loadUrl(str);
		} catch (Exception e) {
			e.printStackTrace();
		}
		try {
			entity.consumeContent();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}


	private HttpEntity getHttpEntity(String url)
	/**
	 * get the http entity at a given url
	 */
	{
		HttpEntity entity = null;
		try {
			DefaultHttpClient httpclient = new DefaultHttpClient();
			HttpGet httpget = new HttpGet(url);
			HttpResponse response = httpclient.execute(httpget);
			entity = response.getEntity();
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
		return entity;
	}

	public int cacheRemaining() {
		File filesDir = mContext.getFilesDir();
		StatFs stats = new StatFs(filesDir.getPath());
		int free =  stats.getFreeBlocks() * stats.getBlockSize();
		return free;
	}

	private void writeToDisk(HttpEntity entity, String file) throws IllegalStateException, IOException
	/**
	 * writes a HTTP entity to the specified filename and location on disk
	 */
	{
		int i = 0;
		InputStream in = entity.getContent();
		byte buff[] = new byte[1024];
		FileOutputStream out = getAssetOutputString(file);
		do {
			int numread = in.read(buff);
			if (numread <= 0)
				break;
			out.write(buff, 0, numread);
			System.out.println("numread" + numread);
			i++;
		} while (true);
		out.flush();
		out.close();
	}

	
	
	
	public FileOutputStream getAssetOutputString(String asset) throws FileNotFoundException {
		File dir = getAssetDir(getAssetPath(asset));
		dir.mkdirs();
		File file = new File(dir, getAssetName(asset));
		return new FileOutputStream(file);
	}


	public void removeAsset(String asset) {
		File dir = getAssetDir(getAssetPath(asset));
		dir.mkdirs();
		File file = new File(dir, getAssetName(asset));
		file.delete();

		String str = "javascript:OrmmaAdController.assetRemoved('" + asset + "' )";
		mOrmmaView.loadUrl(str);
	}

	private File getAssetDir(String path){
		File filesDir = mContext.getFilesDir();
		File newDir = new File (filesDir.getPath() +java.io.File.separator + path);
		return newDir;
	}

	private String getAssetPath(String asset){
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String path = "/";

		
		if (lastSep >=0){
			path = asset.substring(0, asset.lastIndexOf(java.io.File.separatorChar));
		}		
		return path;
	}
	
	private String getAssetName(String asset){
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String name = asset;

		
		if (lastSep >=0){
			name = asset.substring(asset.lastIndexOf(java.io.File.separatorChar)+1);
		}
		return name;
	}
	
}
