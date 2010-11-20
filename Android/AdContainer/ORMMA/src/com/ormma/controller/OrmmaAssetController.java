package com.ormma.controller;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.content.Context;
import android.os.StatFs;

import com.ormma.view.OrmmaView;

public class OrmmaAssetController extends OrmmaController {
	public OrmmaAssetController(OrmmaView adView, Context c) {
		super(adView, c);
	}

	public String copyTextFromJarIntoAssetDir(String alias, String source) {
		try {
			InputStream in = OrmmaAssetController.class.getResourceAsStream(source);
			return writeToDisk(in, alias, false);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

	public void addAsset(String alias, String url) {
		HttpEntity entity = getHttpEntity(url);
		try {
			InputStream in = entity.getContent();
			writeToDisk(in, alias, false);
			String str = "OrmmaAdController.addedAsset('" + alias + "' )";
			mOrmmaView.injectJavaScript(str);
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
		int free = stats.getFreeBlocks() * stats.getBlockSize();
		return free;
	}

	public String writeToDisk(InputStream in, String file, boolean storeInHashedDirectory)
			throws IllegalStateException, IOException
	/**
	 * writes a HTTP entity to the specified filename and location on disk
	 */
	{
		int i = 0;
		byte buff[] = new byte[1024];

		MessageDigest digest = null;
		if (storeInHashedDirectory) {
			try {
				digest = java.security.MessageDigest.getInstance("MD5");
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
			}
		}
		FileOutputStream out = getAssetOutputString(file);
		do {
			int numread = in.read(buff);
			if (numread <= 0)
				break;

			if (storeInHashedDirectory && digest != null) {
				digest.update(buff);
			}
			out.write(buff, 0, numread);
			System.out.println("numread" + numread);
			i++;
		} while (true);
		out.flush();
		out.close();

		String filesDir = getFilesDir();

		if (storeInHashedDirectory && digest != null) {
			filesDir = moveToSubDirectory(file, filesDir, asHex(digest));
		}
		return filesDir + file;

	}

	public String writeToDiskWrap(InputStream in, String file, boolean storeInHashedDirectory)
			throws IllegalStateException, IOException
	/**
	 * writes a HTTP entity to the specified filename and location on disk
	 */
	{
		int i = 0;
		byte buff[] = new byte[1024];

		MessageDigest digest = null;
		if (storeInHashedDirectory) {
			try {
				digest = java.security.MessageDigest.getInstance("MD5");
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
			}
		}
		FileOutputStream out = getAssetOutputString(file);
		boolean first = true;
		boolean js = false;
		
		do {
			int numread = in.read(buff);
			if (numread <= 0)
				break;
			if (first) {
				first = false;
				if(in.toString().trim().startsWith("document.write")){
					out.write("<script>".getBytes());
					js = true;
				}
			}
			if (storeInHashedDirectory && digest != null) {
				digest.update(buff);
			}
			out.write(buff, 0, numread);
			System.out.println("numread" + numread);
			i++;
		} while (true);
		if(js)
			out.write("</script>".getBytes());
		out.flush();
		out.close();

		String filesDir = getFilesDir();

		if (storeInHashedDirectory && digest != null) {
			filesDir = moveToSubDirectory(file, filesDir, asHex(digest));
		}
		return filesDir + file;

	}

	private String moveToSubDirectory(String fn, String filesDir, String subDir) {
		File file = new File(filesDir + java.io.File.separator + fn);
		File dir = new File(filesDir + java.io.File.separator + subDir);
		dir.mkdir();
		file.renameTo(new File(dir, file.getName()));
		return dir.getPath() + java.io.File.separator;
	}

	private static final char[] HEX_CHARS = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd',
			'e', 'f', };

	private String asHex(MessageDigest digest) {
		byte[] hash = digest.digest();
		char buf[] = new char[hash.length * 2];
		for (int i = 0, x = 0; i < hash.length; i++) {
			buf[x++] = HEX_CHARS[(hash[i] >>> 4) & 0xf];
			buf[x++] = HEX_CHARS[hash[i] & 0xf];
		}
		return new String(buf);
	}

	public String getFilesDir() {
		return mContext.getFilesDir().getPath();
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

		String str = "OrmmaAdController.assetRemoved('" + asset + "' )";
		mOrmmaView.injectJavaScript(str);
	}

	private File getAssetDir(String path) {
		File filesDir = mContext.getFilesDir();
		File newDir = new File(filesDir.getPath() + java.io.File.separator + path);
		return newDir;
	}

	private String getAssetPath(String asset) {
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String path = "/";

		if (lastSep >= 0) {
			path = asset.substring(0, asset.lastIndexOf(java.io.File.separatorChar));
		}
		return path;
	}

	private String getAssetName(String asset) {
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String name = asset;

		if (lastSep >= 0) {
			name = asset.substring(asset.lastIndexOf(java.io.File.separatorChar) + 1);
		}
		return name;
	}

	public String getAssetPath() {
		return "file://" + mContext.getFilesDir() + "/";
	}

}
