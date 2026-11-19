/* Orbitrip V3.4: cliente opcional de Supabase. Não inserir service_role aqui. */
(function(){
 "use strict";
 const cfg=window.ORBITRIP_CONFIG||{};
 const ready=Boolean(cfg.supabaseUrl&&cfg.supabaseAnonKey&&window.supabase?.createClient);
 let client=null,activeChannel=null;
 function getClient(){
  if(!ready)throw new Error("Configure o Supabase em config.js para ativar o login.");
  if(!client)client=window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey,{
   auth:{autoRefreshToken:true,persistSession:true,detectSessionInUrl:true}
  });
  return client;
 }
 function checked(result){if(result.error)throw result.error;return result.data}
 function who(){const u=getClient().auth.getUser();return u}
 const api={
  get configured(){return ready},
  async init(){const c=getClient();const {data,error}=await c.auth.getSession();if(error)throw error;return data.session?.user||null},
  async requestCode(email){return checked(await getClient().auth.signInWithOtp({
   email:email.trim().toLowerCase(),options:{shouldCreateUser:true}
  }))},
  async verify(email,token){const data=checked(await getClient().auth.verifyOtp({
   email:email.trim().toLowerCase(),token:token.trim(),type:"email"
  }));return data.user},
  async signOut(){return checked(await getClient().auth.signOut())},
  async list(){
   const c=getClient();
   const {data:{user},error}=await c.auth.getUser();if(error)throw error;if(!user)throw Error("Faça login.");
   const items=checked(await c.from("trips").select("id,owner_id,payload,revision,updated_at").order("created_at",{ascending:true}))||[];
   const memberRows=checked(await c.from("trip_members").select("trip_id,role").eq("user_id",user.id))||[];
   const roles={};for(const m of memberRows)roles[m.trip_id]=m.role;
   for(const t of items)if(t.owner_id===user.id)roles[t.id]="owner";
   return {trips:items,roles,user};
  },
  async write(t,revision,userId){
   const c=getClient();
   if(revision==null){
    const data=checked(await c.from("trips").insert({id:t.id,owner_id:userId,payload:t})
      .select("revision").single());return Number(data.revision);
   }
   const data=checked(await c.rpc("orbitrip_save_trip",{
    p_trip_id:t.id,p_payload:t,p_expected_revision:revision
   }));
   return Number(data);
  },
  async remove(id){
   const data=checked(await getClient().from("trips").delete().eq("id",id).select("id"));
   if(!data||!data.length)throw Error("Só o proprietário pode excluir a viagem.");
  },
  async invite(tripId,role,userId){
   const data=checked(await getClient().from("trip_invites")
    .insert({trip_id:tripId,role,created_by:userId})
    .select("code,expires_at").single());
   return data;
  },
  async accept(code){
   return checked(await getClient().rpc("orbitrip_accept_invite",{p_code:code.trim().toLowerCase()}));
  },
  listen(onChange){
   const c=getClient();if(activeChannel)c.removeChannel(activeChannel);
   const name="orbitrip-"+Math.random().toString(36).slice(2);
   activeChannel=c.channel(name)
     .on("postgres_changes",{event:"*",schema:"public",table:"trips"},onChange)
     .on("postgres_changes",{event:"*",schema:"public",table:"trip_members"},onChange)
     .subscribe();
   return activeChannel;
  },
  stop(){if(activeChannel&&client)client.removeChannel(activeChannel);activeChannel=null}
 };
 window.OrbitripCloud=api;
})();
