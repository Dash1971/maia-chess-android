package org.mobilemaia.releaseprobe;
import android.app.Activity;
import android.os.Bundle;
import android.content.*;
import android.net.Uri;
import android.widget.*;
import java.io.*;
public final class ProbeActivity extends Activity {
 TextView status;
 @Override public void onCreate(Bundle b){super.onCreate(b);LinearLayout l=new LinearLayout(this);l.setOrientation(1);l.setBackgroundColor(android.graphics.Color.WHITE);l.setOnApplyWindowInsetsListener((v,insets)->{android.graphics.Insets bars=insets.getInsets(android.view.WindowInsets.Type.systemBars());v.setPadding(bars.left+16,bars.top+16,bars.right+16,bars.bottom+16);return insets;});status=new TextView(this);status.setTextColor(android.graphics.Color.BLACK);l.addView(status);Button clip=new Button(this);clip.setText("Read clipboard");clip.setAllCaps(false);clip.setOnClickListener(v->{try{ClipboardManager c=(ClipboardManager)getSystemService(CLIPBOARD_SERVICE);if(!c.hasPrimaryClip())throw new Exception("No clipboard");write("clipboard.pgn",c.getPrimaryClip().getItemAt(0).coerceToText(this).toString().getBytes("UTF-8"));status.setText("Clipboard captured");}catch(Exception e){status.setText("ERROR "+e);}});l.addView(clip);setContentView(l);handle(getIntent());}
 @Override protected void onNewIntent(Intent i){super.onNewIntent(i);setIntent(i);handle(i);}
 void write(String n,byte[] b)throws Exception{try(FileOutputStream f=openFileOutput(n,MODE_PRIVATE)){f.write(b);}}
 void handle(Intent i){try{if(Intent.ACTION_SEND.equals(i.getAction())){Uri u=i.getParcelableExtra(Intent.EXTRA_STREAM);if(u==null)throw new Exception("Missing stream");try(InputStream in=getContentResolver().openInputStream(u);ByteArrayOutputStream out=new ByteArrayOutputStream()){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);write("shared.pgn",out.toByteArray());}write("grant.txt",(u.toString()+"\nflags="+i.getFlags()+"\nuid="+android.os.Process.myUid()).getBytes("UTF-8"));status.setText("PGN share received");}else status.setText("Release test probe");}catch(Exception e){status.setText("ERROR "+e);}}
}
