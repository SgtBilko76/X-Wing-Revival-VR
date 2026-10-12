package com.bilko.xwingrevivalvr;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;

import org.libsdl.app.SDLActivity;

/**
 * X-Wing Revival VR entry point. SDL provides the Android lifecycle, input, audio and the
 * GL ES context; the game itself is libmain.so (RaptorEngine + X-Wing Revival).
 * Game data is read from /sdcard/XWingRevival, which needs "All files access".
 */
public class XWingRevivalActivity extends SDLActivity
{
    @Override
    protected void onCreate( Bundle savedInstanceState )
    {
        super.onCreate( savedInstanceState );
        RequestStorageAccess();
    }

    private void RequestStorageAccess()
    {
        if( Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && ! Environment.isExternalStorageManager() )
        {
            try
            {
                Intent intent = new Intent( Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION );
                intent.setData( Uri.parse( "package:" + getPackageName() ) );
                startActivity( intent );
            }
            catch( Exception e )
            {
                startActivity( new Intent( Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION ) );
            }
        }
    }

    @Override
    protected String[] getArguments()
    {
        // Developer testing: adb shell am start ... --es args "-screensaver"
        String args = getIntent() != null ? getIntent().getStringExtra( "args" ) : null;
        if( args == null || args.trim().isEmpty() )
            return new String[0];
        return args.trim().split( "\\s+" );
    }

    @Override
    protected String[] getLibraries()
    {
        return new String[] { "SDL2", "main" };
    }
}
