--  Copyright (C) Simon Wright <simon@pushface.org>

--  This package is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 2, or
--  (at your option) any later version. This package is distributed in
--  the hope that it will be useful, but WITHOUT ANY WARRANTY; without
--  even the implied warranty of MERCHANTABILITY or FITNESS FOR A
--  PARTICULAR PURPOSE. See the GNU General Public License for more
--  details. You should have received a copy of the GNU General Public
--  License distributed with this package; see file COPYING.  If not,
--  write to the Free Software Foundation, 59 Temple Place - Suite
--  330, Boston, MA 02111-1307, USA.

--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this unit does not by itself cause the resulting
--  executable to be covered by the GNU General Public License.  This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.

--  $RCSfile$
--  $Revision$
--  $Date$
--  $Author$

with Ada.Streams;
with GNAT.Sockets; use GNAT.Sockets;

with EWS.Htdocs;
with EWS.Types;

package body EWS.Static is


   type Static_Response (R : HTTP.Request_P)
   is new HTTP.Response (R) with record
      Form : Types.Format;
      Content : Types.Stream_Element_Array_P;
   end record;

   function Content_Type (This : Static_Response) return String;
   function Content_Length (This : Static_Response) return Integer;
   procedure Write_Content (This : Static_Response;
                            To : GNAT.Sockets.Socket_Type);


   function Content_Type (This : Static_Response) return String is
      Format_HTML : aliased constant String
        := "text/html";
      Format_Plain : aliased constant String
        := "text/plain";
      Format_JPEG : aliased constant String
        := "image/jpeg";
      Format_GIF : aliased constant String
        := "image/gif";
      Format_PNG : aliased constant String
        := "image/png";
      Format_Octet_Stream : aliased constant String
        := "application/octet-stream";
      Type_Info : constant array (Types.Format) of Types.String_P
        := (Types.HTML => Format_HTML'Unchecked_Access,
            Types.Plain => Format_Plain'Unchecked_Access,
            Types.JPEG => Format_JPEG'Unchecked_Access,
            Types.GIF => Format_GIF'Unchecked_Access,
            Types.PNG => Format_PNG'Unchecked_Access,
            Types.OCTET_STREAM => Format_Octet_Stream'Unchecked_Access);
   begin
      return Type_Info (This.Form).all;
   end Content_Type;


   function Content_Length (This : Static_Response) return Integer is
   begin
      return This.Content'Length;
   end Content_Length;


   procedure Write_Content (This : Static_Response;
                            To : GNAT.Sockets.Socket_Type) is
      Last : Ada.Streams.Stream_Element_Offset;
   begin
      Send_Socket (To,
                   Item => This.Content.all,
                   Last => Last);
   end Write_Content;


   function Find
     (For_Request : access HTTP.Request) return HTTP.Response'Class is
      subtype Index is Natural range 0 .. Htdocs.Static_Urls'Last;
      function Find (For_URL : String) return Index;
      function Find (For_URL : String) return Index is
      begin
         for I in Htdocs.Static_Urls'Range loop
            if Htdocs.Static_Urls (I).URL.all = For_URL then
               return I;
            end if;
         end loop;
         return 0;
      end Find;
      For_URL : constant HTTP.URL := HTTP.Get_URL (For_Request.all);
      Location : Index;
   begin
      if For_URL'Length = 0 or else For_URL (For_URL'Last) = '/' then
         Location := Find (For_URL & "index.html");
         if Location > 0 then
            return Static_Response'
              (HTTP.Response with
               R => HTTP.Request_P (For_Request),
               Form => Htdocs.Static_Urls (Location).Form,
               Content => Htdocs.Static_Urls (Location).Doc);
         end if;
         Location := Find (For_URL & "index.htm");
         if Location > 0 then
            return Static_Response'
              (HTTP.Response with
               R => HTTP.Request_P (For_Request),
               Form => Htdocs.Static_Urls (Location).Form,
               Content => Htdocs.Static_Urls (Location).Doc);
         end if;
         Location := Find (For_URL & "default.html");
         if Location > 0 then
            return Static_Response'
              (HTTP.Response with
               R => HTTP.Request_P (For_Request),
               Form => Htdocs.Static_Urls (Location).Form,
               Content => Htdocs.Static_Urls (Location).Doc);
         end if;
         Location := Find (For_URL & "default.htm");
         if Location > 0 then
            return Static_Response'
              (HTTP.Response with
               R => HTTP.Request_P (For_Request),
               Form => Htdocs.Static_Urls (Location).Form,
               Content => Htdocs.Static_Urls (Location).Doc);
         end if;
      end if;
      Location := Find (For_URL);
      if Location > 0 then
         return Static_Response'
           (HTTP.Response with
            R => HTTP.Request_P (For_Request),
            Form => Htdocs.Static_Urls (Location).Form,
            Content => Htdocs.Static_Urls (Location).Doc);
      end if;
      return HTTP.Not_Found (For_Request);
   end Find;


end EWS.Static;
