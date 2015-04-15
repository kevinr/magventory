#!/usr/bin/env perl

use strict;
use warnings;


my $GOT_FILE = 1;
my $GOT_CSV = 2;
my $WAITING = 0;
my $state = $WAITING;

my ($cur_file, $cur_p1, $cur_p2, $cur_date, $cur_workers, $cur_start, $cur_end, $cur_collection, $cur_magazine, $cur_structure, $cur_notes);
my (@columns, @last_fields);

print "File, P1, P2, Date, Workers, Time Start, Time End, Collection, Magazine Name, Structure, Sheet Notes, Volume, Year, Date Start, Date End, Issue Start, Issue End, Type, Notes, Other Data\n";

while (<>) {
#    print "state is $state\n";
    if ($state == $WAITING) {
        next unless /^--+File/;
        $state = $GOT_FILE;
        redo;
    }
    elsif ($state == $GOT_FILE) {
        if (/^\s*$/) { next; }
        elsif (/^--+File:\s*(.*?)--+\\(\w+)\\(\w+)/) {
            $cur_file = $cur_p1 = $cur_p2 = $cur_date = $cur_workers = $cur_start = $cur_end = $cur_collection = $cur_magazine = $cur_structure = $cur_notes = '';
            @columns = @last_fields = ();
            $cur_file = sanitize($1);
            $cur_p1 = sanitize($2);
            $cur_p2 = sanitize($3);
            next;
        } 
        elsif (/MITSFS Magazine Inventory/) { next; }
        elsif (/^Date:\s*(.*?)\s*$/) { $cur_date = sanitize($1); next; }
        elsif (/^Workers:\s*(.*?)\s*$/) { $cur_workers = sanitize($1); next; }
        elsif (/^Time Start:\s*(.*?)\s*$/) { $cur_start = sanitize($1); next; }
        elsif (/^Time End:\s*(.*?)\s*$/) { $cur_end = sanitize($1); next; }
        elsif (/^Collection:\s*(.*?)\s*$/) { $cur_collection = sanitize($1); next; }
        elsif (/^Magazine Name:\s*(.*?)\s*$/) { $cur_magazine = sanitize($1); next; }
        elsif (/^Structure:\s*(.*?)\s*$/) { $cur_structure = sanitize($1); next; }
        elsif (/^Notes:\s*(.*?)\s*$/) { $cur_notes = sanitize($1); next; } 
        elsif (/^\s*Volume/) {
            $state = $GOT_CSV;
            redo;
        }
        else { next; }
    } elsif ($state == $GOT_CSV) {
        if (/^\s*$/) { next; }
        elsif (/^\s*Volume/) {
            @columns = split /,\s*/;
            @last_fields = ();
            for (my $j = 0; $j < @columns; $j++) {
                push @last_fields, '';
            }
            next;
        }
        elsif (/^--+File/) { $state = $GOT_FILE; redo; } 
        else { 
            my @fields = split /,\s*/;
            print "$cur_file, $cur_p1, $cur_p2, $cur_date, $cur_workers, $cur_start, $cur_end, $cur_collection, $cur_magazine, $cur_structure, $cur_notes, ";
            for (my $i = 0; $i < @columns; $i++) {
                print ", " unless $i == 0;
                my $column = sanitize($columns[$i]);
                my $raw_field = $fields[$i];
                if ($raw_field) {
                    if ($raw_field =~ /\^/) {
                        my $tmp = sanitize($last_fields[$i]);
                        $raw_field =~ s/\^/$tmp/;
                    }
                    else {
                        $last_fields[$i] = $raw_field;
                    }
                } else {
                    $raw_field = "";  # MISSING
                }
                my $field = sanitize($raw_field);
                if ($i > 7) {
                    print "$column: $field" ;
                }
                else {
                    print "$field";
                }
            }
            print "\n";
            next;
        }
    } else { print "DANGER DANGER WILL ROBINSON!\n"; }
}

sub sanitize {
    my $arg = shift;
    $arg =~ s/^\s*//;
    $arg =~ s/\s*$//;
    $arg =~ s/,/;/g;
    return $arg;
}

1;
