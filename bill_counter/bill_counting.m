%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%bill_counting.m - Counts the total sum of paper currency 
%                   from jpg images of money.
% @Authors- David Byrne, Piotr Renau, Marco Cabrera 
% @Project- Comp546 CSUCI Pattern Recognition and Classification 
% @Notes- Included are a set of test images.
%         Just change this path below to test diffrent images.            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dipclf; clear all; close all;
%Begin read image and process 
%a = imread('named_images/good.jpg'); % change path and image name to where images are saved
%a = imread('named_images/mix5_1.jpg');
%a = imread('named_images/mix2.jpg');
%a = imread('named_images/mix4.jpg');
a = imread('named_images/mix2_5.jpg');
%a = imread('named_images/100.jpg');
%a = imread('named_images/5b.jpg');
%a = imread('named_images/1b.jpg');
%a = imread('named_images/mix6_2.jpg');
imshow(a);
Total=0;
x = size(a,1);
y= size(a,2);
if  (x > y) 
    a=imresize(a,[2016 1512]);
else 
   a= imresize(a,[1512 2016]);
end
b= a(:,:,3);
b= erosion(b,2,'rectangular');
c = b < 80;
d= closing(c,2,'rectangular');
e=fillholes(d,1);
f= closing(e,10,'rectangular');
binary_img_l=label(f,Inf,40000,0);
%Measurments of whole bill
msr_cart = measure(binary_img_l,[],{'CartesianBox'},[],Inf,0,0);
msr_point_min = measure(binary_img_l,[],{'Minimum'},[],Inf,0,0);
msr_point_max = measure(binary_img_l,[],{'Maximum'},[],Inf,0,0);
bill_count=size(msr_cart,1);

%For each bill in the image
for i =1:bill_count
  p_max=double(msr_point_max(i));
  p_min=double(msr_point_min(i));
  p_cart=double(msr_cart(i));
  B=dip_array(binary_img_l==i);
  B=B>0;
  %crop out the whole bill (horizontal/vertical bill)
  bills{i}=imcrop(a,[p_min(1) p_min(2) p_cart(1) p_cart(2)]);
  b=bills{i};
  bill= bills{i};
  bill_x = size(bill,2);
  bill_y = size(bill,1);
if bill_x >bill_y 
   
     B=bill;
else 
    B = imrotate(bill,-90);
    
end
 box_x = 195;
 box_y = 175;
 %crop out the number
 numbers{i}=imcrop(B,[0 0 box_x box_y]);
end
%cut each number out of each bill
for i=1:bill_count
 first_bill=rgb2gray(numbers{i});
 
 p_cart=double(msr_cart(i));
%preprocessing the corner of a bill
 cornner = first_bill > 130;
 cornner=berosion(cornner,1,1,1); 
 cornner=erosion(cornner,2,'elliptic');
 size(cornner);
 num_labels=label(cornner,Inf,65,2500);
% Fixed size threshold - removal of noise
isOne = 'false';

%Handles Special case of one dollar bill 
stats = regionprops(dip_array(num_labels))
for j=1:size(stats,1)
    if ((stats(j).Area > 850) & (stats(j).Area < 1400))
        if(((stats(j).Centroid(1) > 42) & (stats(j).Centroid(1) < 110)) & ((stats(j).Centroid(2) > 80) & (stats(j).Centroid(2) < 120)))
            num_labels=num_labels==j; 
            isOne='true'
        end
    end
end
%Short circuit code for Non-One dollar bills 
if (strcmp(isOne,'false')==1)
 msr_point_min = measure(num_labels,[],{'Minimum'},[],Inf,0,0);
 p_min=double(msr_point_min(1));
 box_x = 190;
 box_y = p_min(2)+75; % Tries to crop minimal ammount required to analyze 
 num_labels=imcrop(dip_array(num_labels),[0 p_min(2)-2 box_x box_y]);
 num_labels=imrotate(num_labels,-8);
else
  box_x = 190;
  box_y = 175;   
end
 
 %take measurment to remove junk 
 msr_point_min = measure(num_labels,[],{'Minimum'},[],Inf,0,0);
 msr_point_max = measure(num_labels,[],{'Maximum'},[],Inf,0,0);
 label_size=length(msr_point_min); 
 sub_sum = num_labels < 0;
 
 %Anything touching or close to the corner is junk.
 j=0;
 for j=1:label_size
    if (size(msr_point_min) == 0) 
        print('Error in image') 
        break;
    end
    p_min=double(msr_point_min(j));
    p_max=double(msr_point_max(j));
    if (p_min(1) < 10 & p_min(2) < 5) %object touching or near top corner
        sub = num_labels==j;
        sub_sum = sub_sum + sub;
    elseif((p_min(1) == 0) & (p_min(2) > box_y/2))
        sub = num_labels==j;
        sub_sum = sub_sum + sub;
    elseif (p_max(1) >  box_x-3) &  (p_max(2) > box_y-3) %objects touching or near bottom corner 
        sub = num_labels==j;
        sub_sum = sub_sum + sub;
    elseif(p_max(1) >= box_x)    
        sub = num_labels==j;
        sub_sum = sub_sum + sub;
    end  
 end
 num = num_labels > 0;
 num = num-sub_sum; %subtract junk
 num = num >0;
 
 num = bdilation(num,1,-1,0);
 num =label(num,Inf,50,2500); %relable to reindex the objects in image
 
 %anything with diameter less then 10 is junk 
 msr2 = measure(num,[],{'Size'},[],Inf,0,0);
 feret = measure(num,[],{'Feret'},[],Inf,0,0); %measure diameter
 sub = 0;
 feret = double(feret);
 sub_sum = num<0;
 for i=1:size(msr2,1)
    if feret(i,2) < 10
        sub = num == i;
        sub_sum = sub_sum + sub;
    end  
 end
 num = num > 0;
 num = num - sub_sum; %subtract junk
 num = num > 0;

%Final Measurements
msr2 = measure(num,[],{'Size'},[],Inf,0,0);
msr3 = measure(num,[],{'P2A'},[],Inf,0,0);
cir = double(msr3(1));    
msr4 = measure(num,[],{'maximum'},[],Inf,0,0);
msr5 = measure(num,[],{'Feret'},[],Inf,0,0);
feret = double(msr5(1));    

%Start decision tree
max_y=max(msr4);
if ((size(msr2,1)==1) | strcmp(isOne,'true'))
    fprintf('one------------------\n')
    one=num;
    dipshow(i,one);
    Total=Total+1;
elseif (size(msr2,1)==3)
     if ((cir>2 & cir<3.5) & (feret(1)>45))
         Five=num;
         dipshow(Five)
         fprintf('five-------------------\n')
         Total=Total+5;
     else(cir<4.5)
         ten=num;
         dipshow(ten)
         fprintf('small ten-----------------\n')
         Total=Total+10;
     end
elseif(size(msr2,1) >= 4)
    if (cir > 2 & feret(1) > 50)
        Fifty=num;
        dipshow(Fifty)
        fprintf('fifty----------------------\n')
        Total=Total+50;
    elseif(cir < 1.35 & feret(1) < 36)
         fprintf('Twenty-------------------\n')
         twenty=num;
          dipshow(twenty)
          Total=Total+20;
    elseif(cir>1.35 & feret(1)>23)
        Hundred=num;
        dipshow(Hundred)
        fprintf('hundred----------------------\n')
        Total=Total+100;
    end 
else 
    fprintf('Could not identify\n')
end
fprintf('The Total is \n');
disp(Total);

end