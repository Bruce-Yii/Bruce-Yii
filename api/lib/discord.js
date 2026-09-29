import { need } from './security.js';
const API='https://discord.com/api/v10';
function set(v){return new Set(String(v||'').split(',').map(x=>x.trim()).filter(Boolean));}
export function cfg(){return {token:need('DISCORD_BOT_TOKEN'), guilds:set(process.env.DISCORD_GUILD_ALLOWLIST), channels:set(process.env.DISCORD_CHANNEL_ALLOWLIST)};}
export function allowGuild(id,c){return c.guilds.size===0||c.guilds.has(String(id));}
export function allowChannel(id,c){return c.channels.size===0||c.channels.has(String(id));}
export function assertGuild(id,c){if(!allowGuild(id,c))throw new Error('guild not allowed: '+id);}
export function assertChannel(id,c){if(!allowChannel(id,c))throw new Error('channel not allowed: '+id);}
export async function discord(path,c,params={}){
  const u=new URL(API+path);
  for(const [k,v] of Object.entries(params)){if(v===undefined||v===null||v==='')continue;if(Array.isArray(v))v.forEach(x=>u.searchParams.append(k,String(x)));else u.searchParams.set(k,String(v));}
  const r=await fetch(u,{headers:{authorization:'Bot '+c.token,'user-agent':'DiscordReaderMCP/0.3'},cache:'no-store'});
  const t=await r.text(); let d; try{d=t?JSON.parse(t):null}catch{d=t}
  if(!r.ok&&r.status!==202)throw new Error('Discord API '+r.status+': '+(typeof d==='string'?d:JSON.stringify(d)));
  return {status:r.status,data:d};
}
export function slim(m){return {id:m.id,channel_id:m.channel_id,guild_id:m.guild_id,author:m.author?{id:m.author.id,username:m.author.username,global_name:m.author.global_name,bot:!!m.author.bot}:null,content:m.content||'',timestamp:m.timestamp,edited_timestamp:m.edited_timestamp,attachments:(m.attachments||[]).map(a=>({id:a.id,filename:a.filename,url:a.url,content_type:a.content_type,size:a.size})),embeds:(m.embeds||[]).map(e=>({type:e.type,title:e.title,description:e.description,url:e.url,provider:e.provider?.name})),referenced_message_id:m.message_reference?.message_id||null,thread:m.thread?{id:m.thread.id,name:m.thread.name}:null,jump_url:m.guild_id?'https://discord.com/channels/'+m.guild_id+'/'+m.channel_id+'/'+m.id:null};}
