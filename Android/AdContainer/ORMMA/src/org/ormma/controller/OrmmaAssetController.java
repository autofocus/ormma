/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

package org.ormma.controller;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.content.Context;
import android.os.StatFs;

import org.ormma.view.OrmmaView;

/**
 * The Class OrmmaAssetController.  This
 * class handles asset management for orrma
 */
public class OrmmaAssetController extends OrmmaController {
	
	/**
	 * Instantiates a new ormma asset controller.
	 *
	 * @param adView the ad view
	 * @param c the c
	 */
	public OrmmaAssetController(OrmmaView adView, Context c) {
		super(adView, c);
	}

	/**
	 * Copy text file from jar into asset directory.
	 *
	 * @param alias the alias to store it in
	 * @param source the source
	 * @return the path to the copied asset
	 */
	public String copyTextFromJarIntoAssetDir(String alias, String source) {
		try {
			URL url = OrmmaAssetController.class.getClassLoader().getResource(source);
			String file = url.getFile();
			if (file.startsWith("file:")) {
				file = file.substring(5);
			}
			int pos = file.indexOf("!");
			if (pos > 0)
				file = file.substring(0, pos);
			JarFile jf = new JarFile(file);
			JarEntry entry = jf.getJarEntry(source);
			InputStream in = jf.getInputStream(entry);
			String name = writeToDisk(in, alias, false);
			return name;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

	/**
	 * Adds an asset.
	 *
	 * @param alias the alias
	 * @param url the url
	 */
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

	/**
	 * pulls a resource from the web
	 *
	 * @param url the url
	 * @return the http entity
	 */
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

	/**
	 * Cache remaining.
	 *
	 * @return the cache remaining
	 */
	public int cacheRemaining() {
		File filesDir = mContext.getFilesDir();
		StatFs stats = new StatFs(filesDir.getPath());
		int free = stats.getFreeBlocks() * stats.getBlockSize();
		return free;
	}

	/**
	 * Write a stream to disk.
	 *
	 * @param in the input stream
	 * @param file the file to store it in
	 * @param storeInHashedDirectory use a hashed directory name
	 * @return the path where it was stired
	 * @throws IllegalStateException the illegal state exception
	 * @throws IOException Signals that an I/O exception has occurred.
	 */
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
			// System.out.println("numread" + numread);
			i++;
		} while (true);
		out.flush();
		out.close();
		in.close();
		String filesDir = getFilesDir();

		if (storeInHashedDirectory && digest != null) {
			filesDir = moveToAdDirectory(file, filesDir, asHex(digest));
		}
		return filesDir + file;

	}

	/**
	 * Write an input stream to a file wrapping it with ormma stuff
	 *
	 * @param in the input stream
	 * @param file the file to store it in
	 * @param storeInHashedDirectory use a hashed directory name
	 * @return the path where it was stored
	 * @throws IllegalStateException the illegal state exception
	 * @throws IOException Signals that an I/O exception has occurred.
	 */
	public String writeToDiskWrap(InputStream in, String file, boolean storeInHashedDirectory, String injection,
			String bridgePath, String ormmaPath) throws IllegalStateException, IOException
	/**
	 * writes a HTTP entity to the specified filename and location on disk
	 */
	{
		byte buff[] = new byte[1024];
		
		MessageDigest digest = null;
		if (storeInHashedDirectory) {
			try {
				digest = java.security.MessageDigest.getInstance("MD5");
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
			}
		}
		
		//check for html tag in the input
		ByteArrayOutputStream fromFile = new ByteArrayOutputStream();
		do {
			int numread = in.read(buff);
			
			if (numread <= 0){
				break;
			}
			
			if (storeInHashedDirectory && digest != null) {
				digest.update(buff);
			}
			
			fromFile.write(buff, 0, numread);
			
		} while (true);
		
		String wholeHTML = fromFile.toString();
		boolean hasHTMLWrap = wholeHTML.indexOf("<html") >= 0;
		
		//TODO   cannot have injection when full html
		
		StringBuffer wholeHTMLBuffer = null;
		
		if(hasHTMLWrap){
			wholeHTMLBuffer = new StringBuffer(wholeHTML);

            int start = wholeHTMLBuffer.indexOf("/ormma_bridge.js");
            
            if(start <= 0){
            	//TODO error
            }
            
            wholeHTMLBuffer.replace(start, start + "/ormma_bridge.js".length(), "file:/" + bridgePath);
            
            start = wholeHTMLBuffer.indexOf("/ormma.js");
            
            if(start <= 0){
            	//TODO error
            }
            
            wholeHTMLBuffer.replace(start, start + "/ormma.js".length(), "file:/" + ormmaPath);
		}
		
		
		FileOutputStream out = getAssetOutputString(file);
		
		if(!hasHTMLWrap){
			out.write("<html>".getBytes());
			out.write("<head>".getBytes());
			out.write("<meta name='viewport' content='user-scalable=no initial-scale=1.0' />".getBytes());
			out.write("<title>Advertisement</title> ".getBytes());
			
			out.write(("<script src=\"file:/" + bridgePath + "\" type=\"text/javascript\"></script>").getBytes());
			out.write(("<script src=\"file:/" + ormmaPath + "\" type=\"text/javascript\"></script>").getBytes());
	
			if (injection != null) {
				out.write("<script type=\"text/javascript\">".getBytes());
				out.write(injection.getBytes());
				out.write("</script>".getBytes());
			}
			out.write("</head>".getBytes());
			out.write("<body style=\"margin:0; padding:0; overflow:hidden; background-color:transparent;\">".getBytes());
			out.write("<div align=\"center\"> ".getBytes());
		}
		
		if(!hasHTMLWrap){
			out.write(fromFile.toByteArray());
		}
		else{
			out.write(wholeHTMLBuffer.toString().getBytes());
		}
		
		if(!hasHTMLWrap){
			out.write("</div> ".getBytes());
			out.write("</body> ".getBytes());
			out.write("</html> ".getBytes());
		}
	
		out.flush();
		out.close();
		in.close();
		String filesDir = getFilesDir();

		if (storeInHashedDirectory && digest != null) {
			filesDir = moveToAdDirectory(file, filesDir, asHex(digest));
		}
		return filesDir;
	}

	/**
	 * Move a file to ad directory.
	 *
	 * @param fn the filename
	 * @param filesDir the files directory
	 * @param subDir the sub directory
	 * @return the path where it was stored
	 */
	private String moveToAdDirectory(String fn, String filesDir, String subDir) {
		File file = new File(filesDir + java.io.File.separator + fn);
		File adDir = new File(filesDir + java.io.File.separator + "ad");
		adDir.mkdir();
		File dir = new File(filesDir + java.io.File.separator + "ad" + java.io.File.separator + subDir);
		dir.mkdir();
		file.renameTo(new File(dir, file.getName()));
		return dir.getPath() + java.io.File.separator;
	}

	/**
	 * The Constant HEX_CHARS.
	 */
	private static final char[] HEX_CHARS = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd',
			'e', 'f', };

	/**
	 * Builds a hex string
	 *
	 * @param digest the digest
	 * @return the string
	 */
	private String asHex(MessageDigest digest) {
		byte[] hash = digest.digest();
		char buf[] = new char[hash.length * 2];
		for (int i = 0, x = 0; i < hash.length; i++) {
			buf[x++] = HEX_CHARS[(hash[i] >>> 4) & 0xf];
			buf[x++] = HEX_CHARS[hash[i] & 0xf];
		}
		return new String(buf);
	}

	/**
	 * Gets the files dir for the activity.
	 *
	 * @return the files dir
	 */
	private String getFilesDir() {
		return mContext.getFilesDir().getPath();
	}

	/**
	 * Gets the asset output string.
	 *
	 * @param asset the asset
	 * @return the asset output string
	 * @throws FileNotFoundException the file not found exception
	 */
	public FileOutputStream getAssetOutputString(String asset) throws FileNotFoundException {
		File dir = getAssetDir(getAssetPath(asset));
		dir.mkdirs();
		File file = new File(dir, getAssetName(asset));
		return new FileOutputStream(file);
	}

	/**
	 * Removes the asset.
	 *
	 * @param asset the asset
	 */
	public void removeAsset(String asset) {
		File dir = getAssetDir(getAssetPath(asset));
		dir.mkdirs();
		File file = new File(dir, getAssetName(asset));
		file.delete();

		String str = "OrmmaAdController.assetRemoved('" + asset + "' )";
		mOrmmaView.injectJavaScript(str);
	}

	/**
	 * Gets the asset dir.
	 *
	 * @param path the path
	 * @return the asset dir
	 */
	private File getAssetDir(String path) {
		File filesDir = mContext.getFilesDir();
		File newDir = new File(filesDir.getPath() + java.io.File.separator + path);
		return newDir;
	}

	/**
	 * Gets the asset path.
	 *
	 * @param asset the asset
	 * @return the asset path
	 */
	private String getAssetPath(String asset) {
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String path = "/";

		if (lastSep >= 0) {
			path = asset.substring(0, asset.lastIndexOf(java.io.File.separatorChar));
		}
		return path;
	}

	/**
	 * Gets the asset name.
	 *
	 * @param asset the asset
	 * @return the asset name
	 */
	private String getAssetName(String asset) {
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String name = asset;

		if (lastSep >= 0) {
			name = asset.substring(asset.lastIndexOf(java.io.File.separatorChar) + 1);
		}
		return name;
	}

	/**
	 * Gets the asset path.
	 *
	 * @return the asset path
	 */
	public String getAssetPath() {
		return "file://" + mContext.getFilesDir() + "/";
	}

	/**
	 * Delete directory.
	 *
	 * @param path the path
	 * @return true, if successful
	 */
	static public boolean deleteDirectory(String path) {
		if (path != null)
			return deleteDirectory(new File(path));
		return false;
	}

	/**
	 * Delete directory.
	 *
	 * @param path the path
	 * @return true, if successful
	 */
	static public boolean deleteDirectory(File path) {
		if (path.exists()) {
			File[] files = path.listFiles();
			for (int i = 0; i < files.length; i++) {
				if (files[i].isDirectory()) {
					deleteDirectory(files[i]);
				} else {
					files[i].delete();
				}
			}
		}
		return (path.delete());
	}

	/**
	 * Delete old ads.
	 */
	public void deleteOldAds() {
		String filesDir = getFilesDir();
		File adDir = new File(filesDir + java.io.File.separator + "ad");
		deleteDirectory(adDir);
	}

	/* (non-Javadoc)
	 * @see com.ormma.controller.OrmmaController#stopAllListeners()
	 */
	@Override
	public void stopAllListeners() {
		// TODO Auto-generated method stub

	}
}
